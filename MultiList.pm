#
#  MultiList.pm
#  Defines a MultiList class, for the simple creation and manipulation
#  of arrays of lists.
#       
#               peg0    peg1    peg2        pegN-1   
#           -----#-------#-------#--- ... ---#-----------
#                1       1       1           1
#                2       2       2           2
#                        3       3           3
#                        4                   4
#                        5
#
#  Created by Alen Bou-Haidar on 24/09/14, edited 24/9/14
#

package MultiList;

use strict;
use warnings;

# constructor
sub new {
    my ($class, @args) = @_;
    my $self = { pegs => [[]] };
    my $object = bless $self, $class;
    return $object;
}

# returns number of pegs
sub get_peg_count {
    my ($self) = @_;
    return scalar @{$self->{pegs}};
}

# append items to peg at peg_index
sub append_to_peg {
    my ($self, $peg_index, @items) = @_;
    my $peg = $self->get_peg($peg_index);
    push @$peg, @items;
}

# append items to last peg
sub append_to_lastpeg {
    my ($self, @items) = @_;
    my $lastpeg_idex = $self->get_peg_count - 1;
    $self->append_to_peg($lastpeg_idex, @items);
}

# creates new peg at end of pegs array
sub new_peg {
    my ($self) = @_;
    push @{$self->{pegs}}, [];
}

# get peg reference at peg_index
sub get_peg {
    my ($self, $peg_index) = @_;
    # my $pegs = $self->_pegs;
    return @{$self->{pegs}}[$peg_index];
}

# returns true if single peg with no items
sub is_empty {
    my ($self) = @_;
    return ($self->get_peg_count == 1 and @{$self->get_peg(0)} == 0);
}

# returns pegs as a list
sub get_pegs {
    my ($self) = @_;
    return (@{$self->{pegs}});
}

1;