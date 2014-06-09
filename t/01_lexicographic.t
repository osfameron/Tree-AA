package main;
use strict; use warnings;
use Data::Dumper;

use Tree::AA;
use Test::More;
use Test::Exception;

sub create {
    my $tree = Tree::AA->fromList(map { [$_=>$_] } @_);
    ok $tree->debug_check_invariants, 'invariants ok';
    is_deeply [ $tree->keys ], [ sort @_ ];
    return $tree;
}

subtest 'check invariants after addition ASC' => sub {
    create('a'..'z');
};

subtest 'check invariants after addition DESC' => sub {
    create(reverse 'a'..'z');
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
    my $tree = create('a'..'d');
    is_deeply [ $tree->pairs ], [[qw/a a/], [qw/b b/], [qw/c c/], [qw/d d/]];
};

subtest 'Check deletions' => sub {
    check_delete('a');
    check_delete('a'..'b');
    check_delete('a'..'c');
    check_delete('a'..'d');
    check_delete('a'..'z');
    check_delete(reverse 'a'..'z');
};

subtest 'fmap' => sub {
    my $tree = create('a'..'c');
    is_deeply [ $tree->pairs ], [[qw/a a/], [qw/b b/], [qw/c c/]];

    $tree = $tree->fmap( sub { uc $_[1] } );

    is_deeply [ $tree->pairs ], [[qw/a A/], [qw/b B/], [qw/c C/]];
};

subtest 'filter' => sub {
    my $tree = create('a'..'z');

    $tree = $tree->filter( sub { $_[0] =~/[aeiou]/ } );
    is_deeply [ $tree->pairs ], [[qw/a a/], [qw/e e/], [qw/i i/], [qw/o o/], [qw/u u/]];
};

subtest 'insert with' => sub {
    my $tree = Tree::AA->new->insert( foo => 1 );

    dies_ok {
        $tree = $tree->insert( foo => 1 );
    } "By default, can't insert duplicate";

    lives_ok {
        $tree = $tree->insert( foo => 2, sub { $_[0] + $_[1] } );
        is_deeply [ $tree->pairs ], [[foo => 3 ]], 'merged value is ok';
    } 'Can insert when a sub is provided';

};

subtest 'fromSortedList' => sub {
    for my $size (0..26) {
        my @list = ('a'..'z');

        my $tree = Tree::AA->fromSortedList( map { [ $_=>$_ ] } @list[0..($size-1)] );
        ok $tree->debug_check_invariants, 'invariants ok';
    }
};

done_testing;
