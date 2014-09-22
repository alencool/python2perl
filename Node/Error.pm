package Node::Error;

use parent 'Node';
use strict;
use warnings;

# initialization
sub _init {
    my ($self) = @_;
    $self->{kind} = 'ERROR';
}


1;