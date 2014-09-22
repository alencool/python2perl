package Node;

use strict;
use warnings;
use Carp;

# constructor
sub new {
    my ($class, $value) = @_;
    my $self = { value      => '',      # str value to infer kind
                 kind       => '',      # what kind of node is it
                 type       => undef,   # for use in infering var types
                 comment    => '',      # possible comment attached
                 complete   => 1,       # is contents full
                 parent     => undef,   # parent node
                 prev       => undef,   # left sibling
                 next       => undef,   # right sibling
                 children   => [],      # child nodes
                 depth      => 0 };     # indentation level
    my $object = bless $self, $class;
    $self->_init($value);
    return $object;
}

# initialization
sub _init {
    my ($self, $value) = @_;
    $self->{value} = $value;
    $self->{kind} = 'NODE';
}

# get node kind
sub kind {
    my ($self) = @_;
    return $self->{kind};
}

# get node value
sub value {
    my ($self) = @_;
    return $self->{value};
}

# returns "kind|value"
sub signature {
    my ($self) = @_;
    return $self->{kind} . '|' . $self->{value};   
}

# add child node
sub add_child {
    my ($self, $node) = @_;
    carp __PACKAGE__ . " not accepting child nodes at this time"
}

# sets a nodes comment
sub set_comment {
    my ($self, $comment) = @_;
    $self->{comment} = $comment;
}

# return true if node is complete
sub complete {
    my ($self) = @_;
    return $self->{complete};
}

# return true if no parent set
sub is_root {
    my ($self) = @_;
    return defined $self->{parent};
}

# return true if has no children
sub is_leaf {
    my ($self) = @_;
    return  @{$self->{children}} == 0;
}

# return true if node represents a statement
sub is_statement {
    return  0;
}

# return true if node represents a compount statement
sub is_compound {
    return  0;
}

# return true if node represents a simple statement
sub is_simple {
    return  0;
}

# attempt to deduce its representive type and return it
sub infer_type {
    return undef;
}

# set node and childrens depth
sub set_depth {
    my ($self, $depth) = @_;
    $self->{depth} = $depth;
    for my $node (@{$self->{children}}) {
        $node->_set_depth($depth + 1);
    }
}

# set node parent
sub set_parent {
    my ($self, $parent) = @_;
    $self->{parent} = $parent;
}

# set right sibling
sub set_right_sibling {
    my ($self, $next) = @_;
    $self->{next} = $next;
}

# set left sibling
sub set_left_sibling {
    my ($self, $prev) = @_;
    $self->{prev} = $prev;
}





# unshift
# shift
# push
# pop
# remove

1;