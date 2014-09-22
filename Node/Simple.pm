package Node::Simple;

use parent 'Node';
use strict;
use warnings;


sub is_statement {
    return  1;
}

sub is_simple {
    return  1;
}


# initialization
sub _init {
    my ($self, $value) = @_;
    $self->{value} = $value;
    $self->{kind} = 'SIMPLE';
    $self->{complete} = 0;
    $self->{children} = [[]];
}

sub add_child {
    my ($self, $node) = @_;

    if ($node->is_statement) {
        croak __PACKAGE__ . " does not accept statments";
    }

    my $children = $self->{children};
    if ($node->signature eq 'SEPERATOR|,') {
        # append new list
        push @$children [];

    } elsif ($node->signature eq 'SEPERATOR|;') {
        # statement complete
        $self->{complete} = 1;

    } else {
        # push child onto last list
        $exp = @$children[$#$children];
        push @$exp $node;
        $node->_set_parent($self);
    }

}

1;