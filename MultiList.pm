#
#  MultiList.pm
#  Defines a MultiList class, for the simple creation and manipulation
#  of arrays of lists.
#       
#              list0   list1   list2       listN-1   
#           -----#-------#-------#--- ... ---#-----------
#                1       1       1           1
#                2       2       2           2
#                        3       3           3
#                        4                   4
#                        5
#
#  Created by Alen Bou-Haidar on 24/09/14, edited 27/9/14
#

package MultiList;

use strict;
use warnings;
use base 'Class::Accessor';
MultiList->mk_accessors(qw(lists));

# constructor
sub new {
    my ($class, @args) = @_;
    my $self = { lists => [[]] };
    my $object = bless $self, $class;
    return $object;
}

# returns number of items
sub item_count {
    my ($self) = @_;
    my $total = 0; 
    foreach my $list (@{$self->lists}) {
        $total += scalar @$list;
    }
    return $total;
}

# returns number of lists
sub list_count {
    my ($self) = @_;
    return scalar @{$self->lists};
}

# append items to last list
sub append {
    my ($self, @items) = @_;
    my $list = $self->lists->[-1];
    push @$list, @items;
}

# append items to list at list_index
sub append_at {
    my ($self, $list_index, @items) = @_;
    my $list = $self->lists->[$list_index];
    push @$list, @items;
}

# creates new list
sub new_list {
    my ($self) = @_;
    push @{$self->lists}, [];
}

# return list reference at index
sub get_list {
    my ($self, $index) = @_;
    return $self->lists->[$index];
}

# returns true if single list with no items
sub is_empty {
    my ($self) = @_;
    return ($self->list_count == 1 and $self->item_count == 0);
}

# returns true if single list with a single items
sub is_single {
    my ($self) = @_;
    return ($self->list_count == 1 and $self->item_count == 1);
}

# return the first item of the first list
sub get_single {
    my ($self) = @_;
    $self->lists->[0][0]
}

# returns a list of list references
sub get_lists {
    my ($self) = @_;
    return (@{$self->lists});
}

# removes last list if empty
sub chomp {
    my ($self) = @_;
    my $list = $self->get_list(-1);
    pop @{$self->lists} unless @$list;
}

1;