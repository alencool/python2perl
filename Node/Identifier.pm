package Node::Identifier;

use parent 'Node';
use strict;
use warnings;


# initialization
sub _init {
    my ($self, $value) = @_;
    $self->{value} = $value;
    $self->{kind} = 'IDENTIFIER';
}

1;