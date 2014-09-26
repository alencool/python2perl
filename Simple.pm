#
#  Simple.pm
#  Defines is a set of classes that represent simple statments in 
#  python for use in the creation of a tree.
#
#  Created by Alen Bou-Haidar on 26/09/14, edited 26/9/14
#

use strict;
use warnings;
use MultiList;
use feature 'switch';

#-----------------------------------------------------------------------
#  ___ _            _       _  _         _        
# / __(_)_ __  _ __| |___  | \| |___  __| |___ ___
# \__ \ | '  \| '_ \ / -_) | .` / _ \/ _` / -_|_-<
# |___/_|_|_|_| .__/_\___| |_|\_\___/\__,_\___/__/
#             |_|                                 
#-----------------------------------------------------------------------
package Node::Simple;
use Constants;
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

sub to_string {
    my ($self, $name) = @_;
    my $string = '';
    $name = $self->value unless defined $name;
    if (not $self->is_leaf){
        my $args = $self->join_children;
        $string = sprintf "%s%s %s;", $self->indent, $name, $args;
    }
    return sprintf "%s%s", $string , $self->comment;
}

#-----------------------------------------------------------------------
package Node::Invisible;
use base 'Node::Simple';

sub kind {
    return 'INVISIBLE';
}
sub to_string {
    my ($self) = @_;
    return $self->comment;
}


#-----------------------------------------------------------------------
package Node::Break;
use Constants;
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
use Constants;
use base 'Node::Simple';

sub kind {
    return 'EXPRESSION';
}
#expression nodes are passed the TypeManager. which it then modifies

# adds child the last open tuple, if none then creates it
sub _add_to_tuple {
    my ($self, $node) = @_;
    my $peg = $self->children->get_peg(0);
    my $lastitem = $$peg[-1];
    if (not $lastitem or $lastitem->complete) {
        $lastitem = new Node::Encloser('(');
        push @$peg, $lastitem;
    }
    $lastitem->add_child($node);
}

sub _on_event_add_child {
    my ($self, $node) = @_;
    my $add_child = FALSE;
    given ($node->kind) {
        when ('TUPLE')          { $add_child = TRUE }
        when ('ASSIGNMENT')     { $add_child = TRUE }
        when ('STMT_SEPERATOR') { $self->complete(TRUE) }
        when ('COLN_SEPERATOR') { $self->complete(TRUE) }
        default                 { $self->_add_to_tuple($node) }
    }
    return $add_child;
}

# returns string representation of a conditional expression
sub to_string_as_conditional {
    my ($self) = @_;
    my $peg = $self->children->get_peg(0);
    my @elements = map {$_->kind} @$peg;
    my $conditional = join(' ', @elements);
    $conditional = "($conditional)" if $conditional;
    return $conditional;
}
#-----------------------------------------------------------------------
package Node::Print;
use base 'Node::Simple';


sub to_string {
    my ($self) = @_;
    return $self->SUPER::to_string('print');
}

sub kind {
    return 'PRINT';
}

#-----------------------------------------------------------------------
package Node::Return;
use base 'Node::Simple';

sub kind {
    return 'RETURN';
}

1;