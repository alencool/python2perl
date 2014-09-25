#
#  Node.pm
#  Node is a set of classes that define the abstract structure of 
#  python code. It can be used to store information or other nodes in 
#  the creation of a tree.
#
#  Created by Alen Bou-Haidar on 20/09/14, edited 25/9/14
#

use strict;
use warnings;
use MultiList;
use feature 'switch';
use constant TRUE   => 1;
use constant FALSE  => 0;

#-----------------------------------------------------------------------
#  ___                 _  _         _     
# | _ ) __ _ ___ ___  | \| |___  __| |___ 
# | _ \/ _` (_-</ -_) | .` / _ \/ _` / -_)
# |___/\__,_/__/\___| |_|\_\___/\__,_\___|
# 
#-----------------------------------------------------------------------
package Node;
use base 'Class::Accessor';
Node->mk_accessors(qw(value type comment complete is_compound is_simple 
                      depth parent prev next children ));

# constructor
sub new {
    my ($class, $value) = @_;
    my $self = { value       => $value,  # str value to infer kind
                 type        => undef,   # for use in infering var types
                 comment     => '',      # possible comment attached
                 complete    => TRUE,    # is contents full
                 is_compound => FALSE,   # is compound statement
                 is_simple   => FALSE,   # is simple statement
                 depth       => 0,       # indentation level
                 parent      => undef,   # parent node
                 prev        => undef,   # left sibling
                 next        => undef,   # right sibling
                 children    => new MultiList }

    my $object = bless $self, $class;
    $self->_init($value);
    return $object;
}

# initialization
sub _init {

}

# get node kind
sub kind {
    return 'NODE';
}

# add child node, set its depth, parent and sibling properties
sub add_child {
    my ($self, $node) = @_;
    if ($node->kind eq 'COMMENT') {
        $self->comment($node->value);
    } elsif (not $self->complete) {
        my $okay_to_add = $self->_on_event_add_child($node);
        if ($okay_to_add){
            my $lastpeg = $self->children->get_lastpeg;
            push @$lastpeg, $node;
            $node->parent($self);
            $node->set_depth($self->depth + 1);
            if (@$lastpeg > 1) {
                my $prev_node = $$lastpeg[-2];
                $prev_node->next($node);
                $node->prev($prev_node);
            }
        }
    }
}

# on add child event, return true to add child, false to ignore
sub _on_event_add_child {
    my ($self, $node) = @_;
    return FALSE;
}

# return true if no parent set
sub is_root {
    my ($self) = @_;
    return not defined $self->parent;
}

# return true if has no children
sub is_leaf {
    my ($self) = @_;
    return  $self->children->is_empty;
}

# return true if node represents a statement
sub is_statement {
    my ($self) = @_;
    return ($self->is_simple || $self->is_compound);
}

# attempt to deduce its representive type and return it
sub infer_type {
    return undef;
}

# set node and childrens depth
sub set_depth {
    my ($self, $depth) = @_;
    $self->depth($depth);
    
    # update child nodes recursively
    my @pegs = $self->children->get_pegs;
    for my $peg (@pegs) {
        for my $child (@$peg) {
            $child->set_depth($depth + 1);
        }
    }
}


#-----------------------------------------------------------------------
#  ___ _                   _     _  _         _        
# | __| |___ _ __  ___ _ _| |_  | \| |___  __| |___ ___
# | _|| / -_) '  \/ -_) ' \  _| | .` / _ \/ _` / -_|_-<
# |___|_\___|_|_|_\___|_||_\__| |_|\_\___/\__,_\___/__/ 
#
#-----------------------------------------------------------------------

# Indicates an unrecognised token
package Node::Error;
use base 'Node';

sub kind {
    return 'ERROR';
}

#-----------------------------------------------------------------------

package Node::Arithmetic;
use base 'Node';

sub kind {
    return 'ARITHMETIC';
}

#-----------------------------------------------------------------------
package Node::Assignment;
use base 'Node';

sub kind {
    return 'ASSIGNMENT';
}

#-----------------------------------------------------------------------
package Node::Bitwise;
use base 'Node';

sub kind {
    return 'BITWISE';
}

#-----------------------------------------------------------------------
package Node::Comment;
use base 'Node';

sub kind {
    return 'COMMENT';
}

#-----------------------------------------------------------------------
package Node::Comparison;
use base 'Node';


sub _init {
    my ($self, $value) = @_;
    $self->value('!=') if ($value eq '<>');
}

sub kind {
    return 'COMPARISON';
}

#-----------------------------------------------------------------------
package Node::Encloser;
use base 'Node';
Node::Encloser->mk_accessors(qw(brace_kind));

sub _init {
    my ($self, $value) = @_;

    if  ($value =~ m/^[])}]$/) {
        $self->brace_kind('CLOSER')
    } else {
        $self->complete(FALSE);
        given ($value){
            when ('[') { $self->brace_kind('LIST')  }
            when ('(') { $self->brace_kind('TUPLE') }
            when ('{') { $self->brace_kind('DICT')  }
            default    { die "Not a bracket."       }
        }
    }
}

sub kind {
    my ($self) = @_;
    return $self->brace_kind;
}

sub _on_event_add_child {
    my ($self, $node) = @_;
    my $add_child = FALSE;

    if ($node->kind eq 'COMA_SEPERATOR') {
        $self->children->new_peg; 
    } elsif ($node->kind eq 'COLN_SEPERATOR') {
        $self->children->new_peg;
        $self->brace_kind('SLICE') if ($self->value eq '[');
    } elsif ($node->kind eq 'CLOSER') {
        $self->complete(TRUE);
    } else {
        $add_child = TRUE;
    }

    return $add_child;
}

#-----------------------------------------------------------------------
package Node::Call;
use base 'Node';

sub kind {
    return 'FUNCTION_CALL';
}

sub _on_event_add_child {
    my ($self, $node) = @_;
    my $add_child = FALSE;

    if ($node->kind eq 'COMA_SEPERATOR') {
        $self->children->new_peg; 
    } elsif ($node->kind eq 'CLOSER') {
        $self->complete = TRUE;
    } else {
        $add_child = TRUE;
    }

    return $add_child;
}

#-----------------------------------------------------------------------
package Node::CallInt;
use base 'Node::Call';

#-----------------------------------------------------------------------
package Node::CallLen;
use base 'Node::Call';

#-----------------------------------------------------------------------
package Node::CallOpen;
use base 'Node::Call';

#-----------------------------------------------------------------------
package Node::CallSorted;
use base 'Node::Call';
#-----------------------------------------------------------------------
package Node::CallRange;
use base 'Node::Call';

#-----------------------------------------------------------------------
package Node::MethodCall;
use base 'Node::Call';
Node::MethodCall->mk_accessors(qw(caller));

sub kind {
    return 'METHOD_CALL';
}

sub set_caller {
    my ($self, $caller) = @_;
    $self->caller($caller);
}

#-----------------------------------------------------------------------
package Node::CallWrite;
use base 'Node::MethodCall';

#-----------------------------------------------------------------------
package Node::CallReadline;
use base 'Node::MethodCall';

#-----------------------------------------------------------------------
package Node::CallReadlines;
use base 'Node::MethodCall';

#-----------------------------------------------------------------------
package Node::CallFileinput;
use base 'Node::MethodCall';

#-----------------------------------------------------------------------
package Node::CallAppend;
use base 'Node::MethodCall';

#-----------------------------------------------------------------------
package Node::CallPop;
use base 'Node::MethodCall';

#-----------------------------------------------------------------------
package Node::CallKeys;
use base 'Node::MethodCall';

#-----------------------------------------------------------------------
package Node::CallSplit;
use base 'Node::MethodCall';
#-----------------------------------------------------------------------
package Node::CallJoin;
use base 'Node::MethodCall';

#-----------------------------------------------------------------------
package Node::CallMatch;
use base 'Node::MethodCall';
#-----------------------------------------------------------------------
package Node::CallSearch;
use base 'Node::MethodCall';

#-----------------------------------------------------------------------
package Node::CallSub;
use base 'Node::MethodCall';

#-----------------------------------------------------------------------
package Node::Identifier;
use base 'Node';

sub kind {
    return 'IDENTIFIER';
}

#-----------------------------------------------------------------------
package Node::Stdout;
use base 'Node::Identifier';

#-----------------------------------------------------------------------
package Node::Stdin;
use base 'Node::Identifier';

#-----------------------------------------------------------------------
package Node::Argv;
use base 'Node::Identifier';

#-----------------------------------------------------------------------
package Node::Indent;
use base 'Node';

sub kind {
    return 'INDENT';
}

#-----------------------------------------------------------------------
package Node::In;
use base 'Node';

sub kind {
    return 'IN';
}

#-----------------------------------------------------------------------
package Node::Logical;
use base 'Node';

sub kind {
    return 'LOGICAL';
}

#-----------------------------------------------------------------------
package Node::Newline;
use base 'Node';

sub kind {
    return 'NEWLINE';
}

#-----------------------------------------------------------------------
package Node::Number;
use base 'Node';

sub kind {
    return 'NUMBER';
}

#-----------------------------------------------------------------------
package Node::Seperator;
use base 'Node';

sub kind {
    my ($self) = @_;
    my $kind;
    given($self->value) {
        when (':') { $kind = 'COLN_SEPERATOR'}
        when (',') { $kind = 'COMA_SEPERATOR'}
        when (';') { $kind = 'STMT_SEPERATOR'}
    }
    return $kind;
}

#-----------------------------------------------------------------------
package Node::String;
use base 'Node';

sub kind {
    return 'STRING';
}

sub is_raw {
    my ($self) = @_;
    my $char = substr $self->{value}, 0, 1;
    return ($char eq "'");
}
#-----------------------------------------------------------------------
package Node::Whitespace;
use base 'Node';

sub kind {
    return 'WHITESPACE';
}

#-----------------------------------------------------------------------
#  ___ _            _       _  _         _        
# / __(_)_ __  _ __| |___  | \| |___  __| |___ ___
# \__ \ | '  \| '_ \ / -_) | .` / _ \/ _` / -_|_-<
# |___/_|_|_|_| .__/_\___| |_|\_\___/\__,_\___/__/
#             |_|                                 
#-----------------------------------------------------------------------
package Node::Simple;
use base 'Node';

sub _init {
    my ($self, $value) = @_;
    $self->is_simple(TRUE);
    $self->complete(FALSE);
}

sub _on_event_add_child {
    my ($self, $node) = @_;
    my $add_child = FALSE;
    given ($node->kind) {
        when ('COMA_SEPERATOR') { $self->children->new_peg }
        when ('STMT_SEPERATOR') { $self->complete(TRUE)    }
        default                 { $add_child = TRUE        }
    }
    return $add_child;
}

#-----------------------------------------------------------------------
package Node::Invisible;
use base 'Node::Simple';

sub kind {
    return 'INVISIBLE';
}

#-----------------------------------------------------------------------
package Node::Break;
use base 'Node';

sub _init {
    my ($self) = @_;
    $self->is_simple(TRUE);
}

sub kind {
    return 'BREAK';
}

#-----------------------------------------------------------------------
package Node::Continue;
use base 'Node::Break';

sub kind {
    return 'CONTINUE';
}

#-----------------------------------------------------------------------
package Node::Expression;
use base 'Node::Simple';

#implement as a list of multilists
#Or .. Create a tuple to store Target lists or entries..
tuple
assigment operator
tuple 
Assigment operator
if node is not tuple then create referece.. 

when assimgnet .. check last item is complete or not.. if not complete then complete it with
tuple.. add... 
non-tuple non-assigment , check last argument.. . open tuple



sub kind {
    return 'EXPRESSION';
}

// overwrite native add_child method!

#method
     add nontuple...
        _get_open_tuple.. if none exists. create it.
     add tuple.. add it like normal

     add assigment.. check to see if open_tuple.. if so close it. then append assigment as normal

     expression nodes are passed the TypeManager. which it then modifies

sub _get_lastitem()     

sub _on_event_add_child {
    my ($self, $node) = @_;


    $self->SUPER::_on_event_add_child($node);
    
    my $add_child = FALSE;
    given ($node->kind) {
        when ('COMA_SEPERATOR') { $self->{children}->new_peg }
        when ('STMT_SEPERATOR') { $self->{complete} = TRUE   }
        when ('ASSIGNMENT')     {  #check to see if assigment has come up previously
                                   #if not then create Multilist 

                                #TODO
                                }
        default                 { $add_child = TRUE          }
    }
    return $add_child;
}

#-----------------------------------------------------------------------
package Node::Print;
use base 'Node::Simple';

sub kind {
    return 'PRINT';
}

#-----------------------------------------------------------------------
package Node::Return;
use base 'Node::Simple';

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
use base 'Node';

sub is_compound {
    return  1;
}

sub kind {
    return 'COMPOUND';
}

#-----------------------------------------------------------------------
package Node::If;
use base 'Node::Compound';

sub kind {
    return 'IF';
}

#-----------------------------------------------------------------------
package Node::Elif;
use base 'Node::Compound';

sub kind {
    return 'ELIF';
}

#-----------------------------------------------------------------------
package Node::Else;
use base 'Node::Compound';

sub kind {
    return 'ELSE';
}

#-----------------------------------------------------------------------
package Node::For;
use base 'Node::Compound';

sub kind {
    return 'FOR';
}

#-----------------------------------------------------------------------
package Node::While;
use base 'Node::Compound';

sub kind {
    return 'WHILE';
}

#-----------------------------------------------------------------------
package Node::Def;
use base 'Node::Compound';

sub kind {
    return 'DEF';
}

#-----------------------------------------------------------------------

package Node::Code;
use base 'Node';

sub _init {
    my ($self) = @_;
    $self->complete(FALSE);
}

sub kind {
    return 'CODE';
}

sub add_child {
    my ($self, $node) = @_;
    
    push @{$self->children}, $node;
    $node->_set_parent($self);

}

1;