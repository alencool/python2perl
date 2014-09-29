#
#  Node.pm
#  Defines the base for a set of classes that represent the abstract 
#  structure of python code. It can be used to store information or 
#  other nodes in the creation of a tree.
#
#  Created by Alen Bou-Haidar on 20/09/14, edited 26/9/14
#

use strict;
use warnings;
use MultiList;
use feature 'switch';


#-----------------------------------------------------------------------
#  ___                 _  _         _     
# | _ ) __ _ ___ ___  | \| |___  __| |___ 
# | _ \/ _` (_-</ -_) | .` / _ \/ _` / -_)
# |___/\__,_/__/\___| |_|\_\___/\__,_\___|
# 
#-----------------------------------------------------------------------
package Node;
use Constants;
use Type;
use base 'Class::Accessor';
Node->mk_accessors(qw(value type comment complete is_compound is_simple 
                      depth parent prev next children ));

# constructor
sub new {
    my ($class, $value) = @_;
    $value = '' unless defined $value;
    my $type = new Type('NUMBER');
    my $self = { value       => $value,  # str value to infer kind
                 type        => $type,   # for use in infering var types
                 comment     => '',      # possible comment attached
                 complete    => TRUE,    # is contents full
                 is_compound => FALSE,   # is compound statement
                 is_simple   => FALSE,   # is simple statement
                 depth       => -1,      # indentation level
                 parent      => undef,   # parent node
                 prev        => undef,   # left sibling
                 next        => undef,   # right sibling
                 children    => new MultiList };

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
            my $list = $self->children->get_list(-1);
            push @$list, $node;
            $node->parent($self);
            $node->set_depth($self->depth + 1);
            if (@$list > 1) {
                my $prev_node = $list->[-2];
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

# set node and childrens depth
sub set_depth {
    my ($self, $depth) = @_;
    $self->depth($depth);
    
    # update child nodes recursively
    my @lists = $self->children->get_lists;
    for my $list (@lists) {
        for my $child (@$list) {
            $child->set_depth($depth + 1);
        }
    }
}

# returns string representation of itself
sub to_string {
    my ($self) = @_;
    return $self->value;
}

# return indent string based on depth
sub indent {
    my ($self) = @_;
    return ("    " x $self->depth);
}

# returns nodes joined together by a seperator
sub join_nodes {
    my ($self, $nodes, $node_sep) = @_;
    my ($string, @node_strings);
    @node_strings = map {$_->to_string} @$nodes;
    return  join($node_sep, @node_strings);

}

# returns nodes of multilist joined together by seperators
# useful for when a node manages multiple multilists
sub join_multilist {
    my ($self, $multilist, @list_sep) = @_;
    my (@lists, @list_strings, $lastitem, $i);
    $list_sep[0] = $list_sep[0] || ', ';
    $list_sep[1] = $list_sep[1] || $list_sep[0];
    @lists = $multilist->get_lists;
    @list_strings = map {$self->join_nodes($_, ' ')} @lists;
    $lastitem = pop @list_strings;
    @list_strings = map {$i = !$i; $_ . $list_sep[!$i]} @list_strings;
    return join('', (@list_strings, $lastitem));
}

# returns children joined together by seperators
sub join_children {
    my ($self, @list_sep) = @_;
    return $self->join_multilist($self->children, @list_sep);
}


# attempt to deduce its representive type
sub infer_type {
    my ($self, $type_manager) = @_;
    my $multi = $self->children;
    $self->type($self->infer_type_from_multilist($type_manager, $multi));
    return $self->type;
}

# attempt to deduce its representive type from list of nodes
# - order of importance, hash, list, string the default, number
sub infer_type_from_list {
    my ($self, $type_manager, @nodes) = @_;
    my $type = new Type('NUMBER');
    for my $node (@nodes) {
        my $node_t = $node->infer_type($type_manager);
        if ($node_t->kind eq 'HASH') {
            $type = $node_t;
            last;
        } elsif ($node_t->kind eq 'LIST') {
            if ($type->kind eq 'LIST') {
                my @merged = (@{$type->data});
                push @merged, @{$node_t->data};
                $type = new Type(\@merged);
            } else {
                $type = $node_t;
            }
        } elsif ($node_t->kind eq 'STRING' and $type->kind ne 'LIST') {
            $type = new Type('STRING');
        }
    }
    return $type;
}

sub infer_type_from_multilist {
    my ($self, $type_manager, $multi) = @_;
    my (@types, $type);
    my @lists = $multi->get_lists;

    for my $list (@lists){
        if (@$list) {
            $type = infer_type_from_list($type_manager, @$list);
            push @types, $type;
        }
    }
    if (@types > 1) {
        $type = new Type(\@types);
    } elsif (@types == 1){
        $type = $types[0];
    } else {
        $type = new Type('NUMBER');
    }

    return $type;
}


# returns prev,next stored types
sub get_sibling_types {
    my ($self) = @_;
    my $prev = ($self->prev && $self->prev->type->kind);
    my $next = ($self->next && $self->next->type->kind);
    return ($prev, $next)
}

# BITWISE
# ARITHMETIC
# COMPARISON
# IN
# LOGICAL


# perl
# @doubles = (1,2,3,4);

# print @doubles;
# for my $i (@a) {

# }

# urinary ~  
# **
# * / 


# % x   // to /
# + -  . (concatinate
# << >>
# &
# ^
# |
# < <= > >=
# !=  ==  eq ne cmp
# in    ~~   not in   !(  ~~  )
# not   !
# and   &&
# or    ||

1;