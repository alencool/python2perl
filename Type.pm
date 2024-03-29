#
#  Type.pm
#  For the storage and retrieval of type information for identifiers. 
#  Types inlcude: ARRAY, HASH, STRING, NUMBER
#
#  Created by Alen Bou-Haidar on 27/09/14, edited 6/10/14
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
    my $self = { data => $data };
    my $object = bless $self, $class;
    return $object;
}

# type kind of either ARRAY, HASH, STRING or NUMBER
sub kind {
    my ($self) = @_;
    return (ref($self->data) ? ref($self->data) : $self->data);
}

# from key or index given return type
sub get_query {
    my ($self, $key) = @_;
    my $type = new Type('NUMBER');
    my $data = $self->data;
    # set type from hash key
    my $_hash = sub {
        if (%$data) {
            if ($key ~~ %$data) {
                $type = $data->{$key};
            } else {
                my @keys = keys(%$data);
                $type = $data->{$keys[0]} if @keys;
            }
        } 
    };

    # set type from array index
    my $_array = sub {

        if (@$data) {
            if ($key !~ /^\d+?$/) {
                $key = 0;
            } else {
                $key = int($key);
            }
            if (defined $data->[$key]) {
                $type = $data->[$key];
            } elsif (defined $data->[0]) {
                $type = $data->[0];
            }
        } 
    };

    given ($self->kind) {
        when ('STRING') { $type = $self }
        when ('ARRAY')  { $_array->() }
        when ('HASH')   { $_hash->() }
    }
    return $type;
}

# set key or index given type
sub set_query {
    my ($self, $key, $type) = @_;
    my $data = $self->data;
    if ($self->kind eq 'ARRAY') {
        $key = int(eval($key) || 0);
        $data->[$key] = $type;
    } elsif ($self->kind eq 'HASH'){
        $data->{$key} = $type;
    }
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
Type::Manager->mk_accessors(qw(data frames seq ftype funcs));

# constructor
sub new {
    my ($class, @args) = @_;
    my $self = {frames  => [{}],    # new frame when inside function
                funcs   => {},      # stores registered functions
                seq     => [],      # declared name, kind,..
                ftype   => undef,   # function return type
                };

    my $object = bless $self, $class;
    return $object;
}

# returns type from name
sub get_type {
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
sub set_type {
    my ($self, $name, $type) = @_;
    my $frame = $self->frames->[0];
    push @{$self->seq}, ($name, $type->kind);
    $frame->{$name} = $type;
}

# register a function return type
sub register_ftype {
    my ($self, $type) = @_;
    $self->ftype($type);
}

# register function to be notified of param types later
sub register_func {
    my ($self, $name, $node) = @_;
    $self->funcs->{$name} = $node;
}

# request function type, passing param types
sub request_func {
    my ($self, $name, @params) = @_;
    my ($node, $type);
    if ($name ~~ $self->funcs) {
        $node = $self->funcs->{$name};
        $type = $node->infer_type_params($self, @params);    
    } else {
        $type = new Type('NUMBER');
    }

    return $type;
}

# create new stack frame
sub push_frame {
    my ($self) = @_;
    unshift @{$self->frames}, {};
    $self->seq([]);
    $self->ftype(undef);
}

# remove top frame from stack
sub pop_frame {
    my ($self) = @_;
    my $ftype = $self->ftype || new Type('NUMBER');
    shift @{$self->frames};
    return ($ftype, $self->seq);
}


1;