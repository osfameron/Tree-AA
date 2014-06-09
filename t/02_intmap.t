package main;
use strict; use warnings;
use Data::Dumper;

use Tree::AA;
use Test::More;
use Test::Exception;

my $IntMap = Tree::AA->with_cmp( sub { $_[0] <=> $_[1] } );

sub create {
    my $tree = $IntMap->fromList( map [$_=>$_], @_ );
    ok $tree->debug_check_invariants, 'invariants ok';
    is_deeply [ $tree->keys ], [ sort { $a <=> $b } @_ ]
        or die Dumper($tree);
    return $tree;
}

subtest 'sanity' => sub {
    is $IntMap, 'Tree::AA::A001';
    isa_ok $IntMap->NIL, $IntMap;
    isa_ok $IntMap->new_node( key => 1, value => 1), "${IntMap}::Node";

    is $IntMap->can('cmp')->(2, 10), -1;
    is 2 <=> 10, -1;
};

subtest 'check invariants after addition ASC' => sub {
    create(8..10);
};

subtest 'check invariants after addition ASC' => sub {
    create(1..16);
};

subtest 'check invariants after addition DESC' => sub {
    create(reverse 1..16);
};

sub check_delete {
    my $tree = create(@_);
    my $was = $tree;
    for (@_) {
        $tree = $tree->delete($_);
        ok $tree->debug_check_invariants, "checked invariants after deletion of $_"
            or do {
                diag $tree->debug_tree;
                diag "WAS " . $was->debug_tree;
                last;
            }
    }
    ok ! $tree->level, 'Tree fully deleted';
}

subtest 'pairs' => sub {
    my $tree = create(1..4);
    is_deeply [ $tree->pairs ], [[1,1], [2,2], [3,3], [4,4 ]];
};

subtest 'Check deletions' => sub {
    check_delete(1);
    check_delete(1..2);
    check_delete(1..3);
    check_delete(1..4);
    check_delete(1..5);
    check_delete(1..16);
    check_delete(reverse 1..16);
};

subtest 'fmap' => sub {
    my $tree = create(1..3);
    is_deeply [ $tree->pairs ], [[1,1], [2,2], [3,3]];

    $tree = $tree->fmap( sub { $_[0] * 2 } );

    is_deeply [ $tree->pairs ], [[1,2], [2,4], [3,6]];
};

subtest 'filter' => sub {
    my $tree = create(1..7);

    $tree = $tree->filter( sub { $_[0] % 3 } );
    is_deeply [ $tree->pairs ], [[1,1], [2,2], [4,4], [5,5], [7,7]];
};

subtest 'insert with' => sub {
    my $tree = $IntMap->new->insert( 1 => 1 );

    dies_ok {
        $tree = $tree->insert( 1 => 2 );
    } "By default, can't insert duplicate";

    lives_ok {
        $tree = $tree->insert( 1 => 2, sub { $_[0] + $_[1] } );
        is_deeply [ $tree->pairs ], [[1 => 3 ]], 'merged value is ok';
    } 'Can insert when a sub is provided';

};

subtest 'fromSortedList' => sub {
    for my $size (0..16) {
        my $tree = $IntMap->fromSortedList( map [$_], 0..$size );
        ok $tree->debug_check_invariants, 'invariants ok';
    }
};

done_testing;
