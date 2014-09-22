package Node::Code;

use parent 'Node';
use strict;
use warnings;
use Carp

# initialization
sub _init {
    my ($self) = @_;
    $self->{kind} = 'CODE';
    $self->{complete} = 0;
}


sub add_child {
    my ($self, $node) = @_;

    if (not $node->is_statement) {
        croak __PACKAGE__ . " only accepts statments";
    }
    
    push @{$self->{children}} $node;
    $node->_set_parent($self);

}

1;
