package Node::Arithmetic;

use parent 'Node';
use strict;
use warnings;


# initialization
sub _init {
    my ($self, $value) = @_;
    $value = '!=' if ($value eq '<>');
    $self->{value} = $value;
    $self->{kind} = 'ARITHMETIC';
}


1;