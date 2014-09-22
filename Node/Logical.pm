package Node::Logical;

use parent 'Node';
use strict;
use warnings;

# initialization
sub _init {
    my ($self, $value) = @_;
    $self->{value} = $value;
    $self->{kind} = 'LOGICAL';
}

1;