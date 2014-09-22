package Node::Encloser;

use parent 'Node';
use strict;
use warnings;


# initialization
sub _init {
    my ($self, $value) = @_;

    if  ($value =~ m/^[])}]$/) {
        # All set up
    } else {
        $self->{complete} = 0;
        $self->{children} = [[]];
        if ($value eq '[') {
            $self->{closevalue} = ']';
        } elsif ($value eq '{') {
            $self->{closevalue} = '}';
        } elsif ($value eq '(') {
            $self->{closevalue} = ')';
        } else {
            croak __PACKAGE__ . " not a bracket.";
        }

    } else {
        croak __PACKAGE__ . " not a bracket.";
    }

    $self->{value} = $value;
    $self->{kind} = 'ENCLOSER';
    
}

sub add_child {
    my ($self, $node) = @_;

    if ($node->is_statement) {
        croak __PACKAGE__ . " does not accept statments";
    }

    my $children = $self->{children};
    if ($node->signature ~~ ['SEPERATOR|,', 'SEPERATOR|:']){
        # append new list
        push @$children [];

    } elsif ($node->signature eq $self->{closevalue}) {
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