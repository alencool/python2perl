package Node::Return;

use parent 'Node::Simple';
use strict;
use warnings;
use Carp



# initialization
sub _init {
    my ($self, $value) = @_;
    $self->SUPER::_init($value);
    $self->{kind} = 'RETURN';
}

1;