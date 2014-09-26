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
use base 'Class::Accessor';
Node->mk_accessors(qw(value type comment complete is_compound is_simple 
                      depth parent prev next children ));

# constructor
sub new {
    my ($class, $value) = @_;
    $value = '' unless defined $value;
    my $self = { value       => $value,  # str value to infer kind
                 type        => undef,   # for use in infering var types
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
    my @node_strings = map {$_->to_string} @$nodes;
    return join($node_sep, @node_strings);

}

# returns children joined together by seperators
sub join_children {
    my ($self, $peg_sep, $child_sep) = @_;
    my (@pegs, @peg_strings);
    $peg_sep = ', ' unless defined $peg_sep;
    $child_sep = ' ' unless defined $child_sep;
    @pegs = $self->children->get_pegs;
    @peg_strings = map {$self->join_nodes($_, $child_sep)} @pegs;
    return join ($peg_sep, @peg_strings);
}

1;