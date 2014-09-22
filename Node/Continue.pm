package Node::Continue;

use parent 'Node::Simple';
use strict;
use warnings;

# initialization
sub _init {
    my ($self, $value) = @_;
    $self->SUPER::_init($value);
    $self->{kind} = 'CONTINUE';
    $self->{complete} = 1;
}

1;