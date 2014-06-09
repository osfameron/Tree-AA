=head1 NAME

Tree::AA - a simple, purely functional, balanced tree

=head1 SYNOPSIS

    my $tree = Tree::AA->new(); # string keys

    my $IntMap = Tree::AA->cmp( $_[0] <=> $_[1] ); # numeric keys
    my $tree = $IntMap->new;

    $tree = $tree->insert( 5 => 'five' );
    $tree = $tree->insert( 10 => 'ten' );

    $tree = $tree->delete( 5 );

=head1 NOTES

Full descriptions of the algorithm are at
L<http://en.wikipedia.org/wiki/AA_tree>
and L<http://www.eternallyconfuzzled.com/tuts/datastructures/jsw_tut_andersson.aspx>

The latter especially was useful for details of the deletion implementation.

=cut

package Tree::AA;
use Moo;

sub level { 0 }
sub value { die }

sub cmp { $_[0] cmp $_[1] }

use constant NIL => Tree::AA->new;

sub new_node {
    my $class = shift;
    require Tree::AA::Node;
    Tree::AA::Node->new(@_);
}

sub insert {
    my ($self, $key, $value, $merge_fn) = @_;
    return $self->new_node(key => $key, value => $value);
}

# simplest algorithm is by defining most methods to just return self
sub but { $_[0] }
sub delete { $_[0] }
sub fmap { $_[0] }
sub filter { $_[0] }

sub keys {}
sub values {}
sub pairs {}

sub left { $_[0] }
sub right { $_[0] }

sub skew { $_[0] }
sub split { $_[0] }

sub debug_tree { '' }
sub debug { '()' }
sub _debug_check_invariants { }

sub debug_check_invariants {
    my $self = shift;
    eval {
        $self->_debug_check_invariants;
    };
    if ($@) {
        Test::More::diag ($@ . "\n" . $self->debug_tree);
        return 0;
    }
    return 1;
}

sub fromList{
    my $class = shift;
    my $root = $class->new;
    for my $pair (@_) {
        $root = $root->insert(@$pair); # key => value
    }
    return $root;
}

sub fromSortedList {
    my $class = shift;
    my $root = $class->_fromSortedList(\@_, 0, scalar @_);
}

sub _fromSortedList{
    my ($class, $array, $from, $to) = @_;
    my $len = $to - $from or return $class->NIL;
    die "Unexpected $from - $to reversed" if $len < 0;
    if ($len == 1) {
        my $item = $array->[$from];
        return $class->new_node( 
            key => $item->[0],
            value => $item->[1]
        );
    }
    if ($len == 2) {
        my $item = $array->[$from];
        my $next = $array->[$from+1];
        return $class->new_node( 
            key => $item->[0],
            value => $item->[1],
            right => $class->new_node(
                key => $next->[0],
                value => $next->[1],
            ),
        );
    }
    my $pivot = int(($len-1) / 2); # 3-1/2=1, e.g. 2nd elem; 4-1/2=1, e.g. 2nd elem, so more elems on right hand side

    my $left  = $class->_fromSortedList($array, $from, $from + $pivot);
    my $right = $class->_fromSortedList($array, $from + $pivot+1, $to);

    my $item = $array->[$from + $pivot];
    return $class->new_node( 
        key => $item->[0],
        value => $item->[1],
        level => $left->level + 1,
        left => $left,
        right => $right,
    );
}

1;
