package Node::Break;

use parent 'Node::Simple';
use strict;
use warnings;

# initialization
sub _init {
    my ($self, $value) = @_;
    $self->SUPER::_init($value);
    $self->{kind} = 'BREAK';
    $self->{complete} = 1;
}

1;