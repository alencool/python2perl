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
Type->mk_accessors(qw(repr, real));

# constructor
sub new {
    my ($class, $repr, $real) = @_;
    my $self = { repr => $repr,   # the type it represents
                 real => $real }; # the actual value as stored in a node
    my $object = bless $self, $class;
    return $object;
}

# returns the truth value of its real
sub truth {
    my ($self) = @_;
    my $truth = FALSE
    given ($self->repr) {
        when ('NUMBER') { $truth = TRUE if ($self->real + 0) }
        when ('STRING') { $truth = TRUE if (length($self->real) > 2) }
        when ('HASH')   { $truth = TRUE if (%{$self->real}) }
        when ('ARRAY')  { $truth = TRUE if (@{$self->real}) }
    }
    return $truth;
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

# constructor
sub new {
    my ($class, @args) = @_;
    my $self = { };
    my $object = bless $self, $class;
    return $object;
}

# returns type from name
sub get {
    my ($self, $name) = @_;
    return $self->{$name};
}

# stores type for name
sub set {
    my ($self, $name, $type) = @_;
    $self->{$name} = $type;
}

1;