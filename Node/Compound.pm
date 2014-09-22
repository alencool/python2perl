package Node::Compound;

use parent 'Node';
use strict;
use warnings;


sub is_statement {
    return  1;
}

sub is_compound {
    return  1;
}

# initialization
sub _init {
    my ($self, $value) = @_;
    $self->{value} = $value;
    $self->{kind} = 'COMPOUND';
}

1;