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
        when ('COMA_SEPERATOR') { $self->children->new_list }
        when ('STMT_SEPERATOR') { $self->complete(TRUE)    }
        default                 { $add_child = TRUE        }
    }
    return $add_child;
}

sub to_string {
    my ($self, $name) = @_;
    my $args = ';';
    $name = $self->value unless defined $name;
    if (not $self->is_leaf){
        $args = sprintf " %s;", $self->join_children;
    } 
    return $self->indent.$name.$args.$self->comment;
}

#-----------------------------------------------------------------------
package Node::Invisible;
use base 'Node::Simple';

sub _kind {
    return 'INVISIBLE';
}
sub to_string {
    my ($self) = @_;
    return $self->comment;
}


#-----------------------------------------------------------------------
package Node::Break;
use base 'Node::Simple';

#-----------------------------------------------------------------------
package Node::Continue;
use base 'Node::Simple';

#-----------------------------------------------------------------------
package Node::Expression;
use Constants;
use base 'Node::Simple';
Node::Expression->mk_accessors(qw(targets));

sub _kind {
    return 'EXPRESSION';
}
#expression nodes are passed the TypeManager. which it then modifies

# adds child the last open tuple, if none then creates it
sub _init {
    my ($self) = @_;
    $self->SUPER::_init;
    $self->targets([]);
}

sub infer_type {
    my ($self, $type_manager) = @_;

    # get type from right most multilist
    $self->SUPER::infer_type($type_manager);

    # get all target multilists
    my @targets = @{$self->targets};
    # filter out assigment nodes
    @targets  = @targets[grep $_ % 2, 0..$#targets];
    map {$self->infer_type_from_multilist($type_manager, $_)} @targets;

    $self->_assign_types($type_manager) if @targets;
    
    return $self->type;
}

sub _assign_types {
    my ($self, $type_manager) = @_;
    my (@types, @targets, $node, $type);
    
    # get types
    if ($self->type->kind eq 'ARRAY') {
        @types = @{$self->type->data};
    } else {
        @types = ($self->type->data);
    }

    # assign types to each target
    @targets = @{$self->targets};
    if ($targets[1]->value eq '=') {
        # filter out assigment nodes
        @targets  = @targets[grep $_ % 2, 0..$#targets];
        for $target (@targets) {
            $target->chomp;
            if ($target->list_count == 1) { 
                $node = $target->get_single;
                $node->imply_type($type_manager, $self->type);
            } else {
                for (my $i = 0; $i < $target->list_count; $i++) {
                    $node = @{$target->get_list($i)}[0];
                    $type = $types[$i] || $types[0];
                    $node->imply_type($type_manager, $type);
                }
            }
        }
    }
}

sub to_string {
    my ($self) = @_;
    my (@strings, $string);
    my $node_assigment = TRUE;
    for my $target (@{$self->targets}) {
        $node_assigment = !$node_assigment;
        if ($node_assigment) {
            #target is a Node::Assigment
            push @strings, $target->to_string;
        } else {
            #target is a multilist
            $string = $self->join_multilist($target);
            $string = qq/($string)/ if ($target->list_count > 1);
            push @strings, $string;
        }
    }
    $string = join(' ', @strings);
    $string = $self->indent.$string.';' if $string;
    $string .= $self->comment;
    
    return $string;
}

# output format suitable for a condiional statement
sub to_string_conditional {
    my ($self) = @_;
    my ($multi, $str);
    $multi = $self->targets->[0];
    $str = $self->join_multilist($multi);
    $str = qq/ ($str)/ if $str;
    return $str;
}

sub _on_event_add_child {
    my ($self, $node) = @_;
    my $add_child = FALSE;
    if ($node->kind eq 'ASSIGNMENT') {
        # transformed to assimgnet statement, extract targets
        $self->_peel_multilist;
        push @{$self->targets}, ($self->children, $node);
        $self->children(new MultiList);
    } elsif ($node->kind eq 'COMA_SEPERATOR') {
        # new list for each target expression
        $self->children->new_list;
    } elsif ($node->kind ~~ ['STMT_SEPERATOR', 'COLN_SEPERATOR']){
        # statement completion, extract to target list
        $self->_peel_multilist;
        $self->complete(TRUE);
    } else {
        $add_child = TRUE;
    }
    return $add_child;
}

#-----------------------------------------------------------------------
package Node::Print;
use base 'Node::Simple';


sub to_string {
    my ($self) = @_;
    return $self->SUPER::to_string('print');
}

sub _kind {
    return 'PRINT';
}

#-----------------------------------------------------------------------
package Node::Return;
use base 'Node::Simple';

sub _kind {
    return 'RETURN';
}

1;