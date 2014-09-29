#
#  Type.pm
#  For the storage and retrieval of type information for identifiers. 
#  Types inlcude: ARRAY, HASH, STRING, NUMBER
#
#  Created by Alen Bou-Haidar on 27/09/14, edited 27/9/14
#
use strict;
use warnings;
use feature 'switch';

#-----------------------------------------------------------------------
#  _____               
# |_   _|  _ _ __  ___        
#   | || || | '_ \/ -_)
#   |_| \_, | .__/\___|
#       |__/|_|        
#
#-----------------------------------------------------------------------

package Type;
use Constants;
use base 'Class::Accessor';
Type->mk_accessors(qw(data));

# constructor
sub new {
    my ($class, $data) = @_;
    my $self = { data => $data};
    my $object = bless $self, $class;
    return $object;
}

sub kind {
    my ($self) = @_;
    return (ref($self->data) ? ref($self->data) : $self->data);
}

#-----------------------------------------------------------------------
#  _____               __  __                             
# |_   _|  _ _ __  ___|  \/  |__ _ _ _  __ _ __ _ ___ _ _ 
#   | || || | '_ \/ -_) |\/| / _` | ' \/ _` / _` / -_) '_|
#   |_| \_, | .__/\___|_|  |_\__,_|_||_\__,_\__, \___|_|  
#       |__/|_|                             |___/         
# 
#-----------------------------------------------------------------------

package Type::Manager;
use base 'Class::Accessor';
Type::Manager->mk_accessors(qw(frames));

# constructor
sub new {
    my ($class, @args) = @_;
    my $self = {frames => [{}]};
    my $object = bless $self, $class;
    return $object;
}

# returns type from name
sub get {
    my ($self, $name) = @_;
    my $value = undef;
    for my $frame (@{$self->frames}) {
        if ($name ~~ $frame) {
            $value = $frame->{$name};
            last;
        }
    }
    return $value;
}

# stores type for name
sub set {
    my ($self, $name, $type) = @_;
    my $frame = $self->frames->[0];
    $frame->{$name} = $type;
}

# create new stack frame
sub push_frame {
    my ($self) = @_;
    unshift @{$self->frames}, {};
}

# remove top frame from stack
sub pop_frame {
    my ($self) = @_;
    shift @{$self->frames};
}


1;