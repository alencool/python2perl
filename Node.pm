package Node;

use strict;
use warnings;

########################################################################
#                         Public Methods                               #
########################################################################

# constructor
sub new {
    my ($class, $name, $value) = @_;
    my $self = { name       => $name,
                 value      => $value,
                 parent     => undef,
                 children   => [],
                 depth      => 0 };
    my $object = bless $self, $class;
    return $object;
}


# comment
sub unshift {
    my ($self) = @_;
    return ;
}

# comment
sub shift {
    my ($self) = @_;
    return ;
}

# add children
sub push {
    my ($self, @children) = @_;
    TODO
    return ;
}


sub pop {
    TODO
}


# remove children
sub remove {
    my ($self, @children) = @_;
    TODO
    return ;
}


sub parent {

}


sub is_root {

}

sub is_leaf {

}

########################################################################
#                         Private Methods                              #
########################################################################

sub _set_depth {

}

sub _set_parent {
    
}

1;