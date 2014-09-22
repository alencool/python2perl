use strict;
use warnings;

#-----------------------------------------------------------------------
#  ___                 _  _         _     
# | _ ) __ _ ___ ___  | \| |___  __| |___ 
# | _ \/ _` (_-</ -_) | .` / _ \/ _` / -_)
# |___/\__,_/__/\___| |_|\_\___/\__,_\___|
# 
#-----------------------------------------------------------------------
package Node;

# constructor
sub new {
    my ($class, $value) = @_;
    my $self = { value      => '',      # str value to infer kind
                 type       => undef,   # for use in infering var types
                 comment    => '',      # possible comment attached
                 complete   => 1,       # is contents full
                 parent     => undef,   # parent node
                 prev       => undef,   # left sibling
                 next       => undef,   # right sibling
                 children   => [],      # child nodes
                 depth      => 0 };     # indentation level
    my $object = bless $self, $class;
    $self->_init($value);
    return $object;
}

# initialization
sub _init {
    my ($self, $value) = @_;
    $self->{value} = $value;
}

# get node kind
sub kind {
    return 'NODE';
}

# get node value
sub value {
    my ($self) = @_;
    return $self->{value};
}

# returns signature as "kind|value"
sub signature {
    my ($self) = @_;
    return $self->kind . '|' . $self->value;   
}

# add child node
sub add_child {
    my ($self, $node) = @_;

    if ($self->_on_event_add_child($node)){
        # All systems are go, can append child node to last rootlist
        my $rootlist = $self->{children};
        my $childlist = @$rootlist[$#$rootlist];
        push @$childlist, $node;
        $node->_set_parent($self);
        #TODO set siblings!
    }
}

# on add child event, return true to add child, false to ignore
sub _on_event_add_child {
    my ($self, $node) = @_;
    return 0;
}

# create new child list
sub _new_child_list {
    my ($self) = @_;
    my $rootlist = $self->{children};
    push @$rootlist, [];
}

# sets a nodes comment
sub set_comment {
    my ($self, $comment) = @_;
    $self->{comment} = $comment;
}

# return true if node is complete
sub complete {
    my ($self) = @_;
    return $self->{complete};
}

# return true if no parent set
sub is_root {
    my ($self) = @_;
    return defined $self->{parent};
}

# return true if has no children
sub is_leaf {
    my ($self) = @_;
    return  @{$self->{children}} == 0;
}

# return true if node represents a statement
sub is_statement {
    my ($self) = @_;
    return ($self->is_simple || $self->is_compound);
}

# return true if node represents a compount statement
sub is_compound {
    return 0;
}

# return true if node represents a simple statement
sub is_simple {
    return  0;
}

# attempt to deduce its representive type and return it
sub infer_type {
    return undef;
}

# set node and childrens depth
sub set_depth {
    my ($self, $depth) = @_;
    $self->{depth} = $depth;
    for my $node (@{$self->{children}}) {
        $node->_set_depth($depth + 1);
    }
}

# set node parent
sub set_parent {
    my ($self, $parent) = @_;
    $self->{parent} = $parent;
}

# set right sibling
sub set_right_sibling {
    my ($self, $next) = @_;
    $self->{next} = $next;
}

# set left sibling
sub set_left_sibling {
    my ($self, $prev) = @_;
    $self->{prev} = $prev;
}

#-----------------------------------------------------------------------
#  ___ _                   _     _  _         _        
# | __| |___ _ __  ___ _ _| |_  | \| |___  __| |___ ___
# | _|| / -_) '  \/ -_) ' \  _| | .` / _ \/ _` / -_|_-<
# |___|_\___|_|_|_\___|_||_\__| |_|\_\___/\__,_\___/__/ 
#
#-----------------------------------------------------------------------


package Node::Arithmetic;
use parent 'Node';

sub kind {
    return 'ARITHMETIC';
}

#-----------------------------------------------------------------------
package Node::Bitwise;
use parent 'Node';

sub kind {
    return 'BITWISE';
}

#-----------------------------------------------------------------------
package Node::Comparison;
use parent 'Node';


sub _init {
    my ($self, $value) = @_;
    $value = '!=' if ($value eq '<>');
    $self->{value} = $value;
}

sub kind {
    return 'COMPARISON';
}

#-----------------------------------------------------------------------
package Node::Encloser;
use parent 'Node';


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
            die "Not a bracket.";
        }

    } else {
        die "Not a bracket.";
    }

    $self->{value} = $value;
    
}

sub kind {
    return 'ENCLOSER';
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

#-----------------------------------------------------------------------
package Node::Identifier;
use parent 'Node';

sub kind {
    return 'IDENTIFIER';
}

#-----------------------------------------------------------------------
package Node::In;
use parent 'Node';

sub kind {
    return 'IN';
}


#-----------------------------------------------------------------------
package Node::Logical;
use parent 'Node';

sub kind {
    return 'LOGICAL';
}

#-----------------------------------------------------------------------
package Node::Number;
use parent 'Node';

sub kind {
    return 'NUMBER';
}

#-----------------------------------------------------------------------
package Node::Seperator;
use parent 'Node';

sub kind {
    return 'SEPERATOR';
}

#-----------------------------------------------------------------------
package Node::String;
use parent 'Node';

sub kind {
    return 'STRING';
}

sub is_raw {
    my ($self) = @_;
    my $char = substr $self->{value} 0 1;

    return ($char eq "'");
}

#-----------------------------------------------------------------------
#  ___ _            _       _  _         _        
# / __(_)_ __  _ __| |___  | \| |___  __| |___ ___
# \__ \ | '  \| '_ \ / -_) | .` / _ \/ _` / -_|_-<
# |___/_|_|_|_| .__/_\___| |_|\_\___/\__,_\___/__/
#             |_|                                 
#-----------------------------------------------------------------------
package Node::Simple;
use parent 'Node';

sub is_simple {
    return  1;
}

sub kind {
    return 'SIMPLE';
}

sub _init {
    my ($self, $value) = @_;
    $self->{value} = $value;
    $self->{complete} = 0;
}

sub _on_event_add_child {
    my ($self, $node) = @_;

    if ($node->is_statement) {
        croak __PACKAGE__ . " does not accept statments";
    }

    my $add_child = 1;
    if ($node->signature eq 'SEPERATOR|,') {
        $self->_new_child_list;

    } elsif ($node->signature eq 'SEPERATOR|;') {
        # statement complete
        $self->{complete} = 1;
    }
    return $add_child;
}

#-----------------------------------------------------------------------
package Node::Assignment;
use parent 'Node::Simple';

sub _init {
    my ($self, $value) = @_;
    $self->SUPER::_init($value);
    $self->{complete} = 1;
}

sub kind {
    return 'ASSIGNMENT';
}
#-----------------------------------------------------------------------
package Node::Blank;
use parent 'Node::Simple';


sub _init {
    my ($self, $value) = @_;
    $self->SUPER::_init($value);
    $self->{complete} = 1;
}

sub kind {
    return 'BLANK';
}

#-----------------------------------------------------------------------
package Node::Break;
use parent 'Node::Simple';

sub _init {
    my ($self, $value) = @_;
    $self->SUPER::_init($value);
    $self->{complete} = 1;
}

sub kind {
    return 'BREAK';
}

#-----------------------------------------------------------------------
package Node::Continue;
use parent 'Node::Simple';

sub _init {
    my ($self, $value) = @_;
    $self->SUPER::_init($value);
    $self->{complete} = 1;
}

sub kind {
    return 'CONTINUE';
}

#-----------------------------------------------------------------------
package Node::Expression;
use parent 'Node::Simple';

sub kind {
    return 'EXPRESSION';
}


#-----------------------------------------------------------------------
package Node::Print;
use parent 'Node::Simple';

sub kind {
    return 'PRINT';
}

#-----------------------------------------------------------------------
package Node::Return;
use parent 'Node::Simple';

sub kind {
    return 'RETURN';
}


#-----------------------------------------------------------------------
#   ___                                  _   _  _         _        
#  / __|___ _ __  _ __  ___ _  _ _ _  __| | | \| |___  __| |___ ___
# | (__/ _ \ '  \| '_ \/ _ \ || | ' \/ _` | | .` / _ \/ _` / -_|_-<
#  \___\___/_|_|_| .__/\___/\_,_|_||_\__,_| |_|\_\___/\__,_\___/__/
#                |_|                                               
#-----------------------------------------------------------------------
package Node::Compound;
use parent 'Node';

sub is_compound {
    return  1;
}

sub kind {
    return 'COMPOUND';
}

#-----------------------------------------------------------------------
package Node::Code;
use parent 'Node';


# initialization
sub _init {
    my ($self) = @_;
    $self->{complete} = 0;
}

sub kind {
    return 'CODE';
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