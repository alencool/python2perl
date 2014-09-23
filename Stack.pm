#
#  Stack.pm
#  Defines a stack class, with a simple interface.
#
#  Created by Alen Bou-Haidar on 23/09/14, edited 24/9/14
#

package Stack;

use strict;
use warnings;


sub new {
    my ($class, @args) = @_;
    my $self = { items => []};
    my $object = bless $self, $class;
    return $object;
}

#returns top item without poping off
sub top {
    my ($self) = @_;
    my $items = $self->{items};
    my $last_index = $#$items;
    my $top = @$items[$last_index];
    return $top;
}
# push item on top of stack
sub push {
    my ($self, $item) = @_;
    push @{$self->{items}}, $item;
}

# pop off top item and return it
sub pop {
    my ($self) = @_;
    my $item = pop @{$self->{items}};
    return $item;
}

1;