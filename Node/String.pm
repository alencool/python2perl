package Node::String;

use parent 'Node';
use strict;
use warnings;


# initialization
sub _init {
    my ($self, $value) = @_;
    $self->{value} = $value;
    $self->{kind} = 'STRING';
}


sub is_raw {
    my ($self) = @_;
    my $char = substr $self->{value} 0 1;

    return ($char eq "'");
}

1;