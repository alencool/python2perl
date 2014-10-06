#
#  Node.pm
#  Defines the base for a set of classes that represent the abstract 
#  structure of python code. It can be used to store information or 
#  other nodes in the creation of a tree.
#
#  Created by Alen Bou-Haidar on 20/09/14, edited 5/10/14
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
                      depth parent prev next children kind subkind));

# constructor
sub new {
    my ($class, $value) = @_;
    $value = '' unless defined $value;
    my $type = new Type('NUMBER');
    my $self = { value       => $value,  # str value
                 kind        => '',      # kind of node
                 subkind     => '',      # sub-kind of node
                 type        => $type,   # stored Type object
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
    # subclass can define their kind/subkind easily 
    # by implementing these private methods
    $self->kind($self->_kind);
    $self->subkind($self->_subkind);
    $self->_init($value);
    return $object;
}

# initialization
sub _init {

}

# init node kind
sub _kind {
    my ($self) = @_;
    $self =~ /::(.+)=HASH/;
    return uc $1;
}

# init node subkind
sub _subkind {
    my ($self) = @_;
    $self =~ /::(.+)=HASH/;
    return uc $1;
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
    my ($self, $nodes, $context) = @_;
    my ($string, @node_strings);
    @node_strings = map {$_->to_string($context)} @$nodes;
    $string = join(' ', @node_strings);
    #adjust for unary operators
    $string =~ s/! /!/g;
    $string =~ s/ ~ / ~/g;
    return  $string;

}

# returns nodes of multilist joined together by seperators
# useful for when a node manages multiple multilists
sub join_multilist {
    my ($self, $multilist, $context, @list_sep) = @_;
    my (@lists, @list_strings, $lastitem, $i);
    $list_sep[0] ||= ', ';
    $list_sep[1] ||= $list_sep[0];
    @lists = $multilist->get_lists;
    @list_strings = map {$self->join_nodes($_, $context)} @lists;
    $lastitem = pop @list_strings;
    @list_strings = map {$i = !$i; $_ . $list_sep[!$i]} @list_strings;
    return join('', (@list_strings, $lastitem));
}

# returns children joined together by seperators
sub join_children {
    my ($self, $context, @list_sep) = @_;
    return $self->join_multilist($self->children, $context, @list_sep);
}


# attempt to deduce its representive type
sub infer_type {
    my ($self, $type_manager) = @_;
    $type_manager = new Type::Manager unless defined $type_manager;
    my $multi = $self->children;
    $self->type($self->infer_from_multilist($type_manager, $multi));
    return $self->type;
}

# attempts to replace % operations on string like nodes with sprintf
sub translate_sprintf {
    my ($self) = @_;
    my @lists = $self->children->get_lists;

    for my $list (@lists) {
        for (my $i = 0; $i < @$list; $i++) {
            if ($list->[$i]->kind eq 'ARITHMETIC' and 
                $list->[$i]->value eq '%' and
                $list->[$i - 1]->type->kind eq 'STRING') {
                # found 'fmt_str % args'
                my $sprintf = new Node::Sprintf::;
                $sprintf->add_child($list->[$i - 1]);   # fmt string
                $sprintf->add_child($list->[$i + 1]);   # args
                splice @$list, $i-1, 3, $sprintf;
            }
        }
        for my $node (@$list) {
            $node->translate_sprintf;
        }    
    }
}

# attempts to contatinate lits using perls list flattening
sub translate_list_add {
    my ($self) = @_;
    my @lists = $self->children->get_lists;
    for my $list (@lists) {
        for (my $i = 1; $i < @$list; $i++) {
            if ($list->[$i]->kind eq 'ARITHMETIC' and 
                $list->[$i]->value eq '+' and
                $list->[$i - 1]->type->kind eq 'ARRAY') {
                # found list +
                my $flat_list = new Node::Flat::;
                $flat_list->add_child($list->[$i - 1]);
                while ($list->[$i] and
                       $list->[$i]->kind eq 'ARITHMETIC' and 
                       $list->[$i]->value eq '+') {
                    $flat_list->add_child($list->[$i + 1]);
                    splice @$list, $i, 2;
                }
                splice @$list, $i-1, 1, $flat_list;
            }
        }
        for my $node (@$list) {
            $node->translate_list_add;
        }    
    }
}

# attempts to replace x not in y => !(x in y)
sub translate_notin {
    my ($self) = @_;
    my @lists = $self->children->get_lists;

    for my $list (@lists) {
        for (my $i = 0; $i < @$list; $i++) {
            if ($list->[$i]->kind eq 'NOT' and 
                $list->[$i + 1]->kind eq 'IN') {
                # found 'not in'
                my @notin = ($list->[$i]);            # operator not
                my $paren = new Node::Tuple::;
                $paren->add_child($list->[$i - 1]);   # left operand
                $paren->add_child($list->[$i + 1]);   # operator in
                $paren->add_child($list->[$i + 2]);   # right operand
                push @notin, $paren;
                splice @$list, $i-1, 4, @notin;
            }
        }
        for my $node (@$list) {
            $node->translate_notin;
        }    
    }
}

# attempt to deduce its representive type from list of nodes
# - order of importance, hash, array, string the default, number
sub infer_from_list {
    my ($self, $type_manager, @nodes) = @_;
    my $type = new Type('NUMBER');
    for my $node (@nodes) {
        
        my $node_t = $node->infer_type($type_manager);
        if ($node_t->kind eq 'HASH') {
            $type = $node_t;
            last;
        } elsif ($node_t->kind eq 'ARRAY') {
            if ($type->kind eq 'ARRAY') {
                my @merged = (@{$type->data});
                push @merged, @{$node_t->data};
                $type = new Type(\@merged);
            } else {
                $type = $node_t;
            }
        } elsif ($node_t->kind eq 'STRING' and $type->kind ne 'ARRAY') {
            $type = new Type('STRING');
        }
    }
    return $type;
}

sub infer_from_multilist {
    my ($self, $type_manager, $multi) = @_;
    my (@types, $type);
    my @lists = $multi->get_lists;

    for my $list (@lists){
        if (@$list) {
            $type = $self->infer_from_list($type_manager, @$list);
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

# removes layers of parenthesis from the children multilist
sub _peel_multilist {
    my ($self, $node) = @_;
    my $children = $self->children;
    while ($children->is_single) {
        $node = $children->get_single;
        if ($node->kind eq 'TUPLE') {
            $children = $node->children;
        } else {
            last;
        }
    }
    $self->children($children);
}

# returns a modified 'exp' list, by modulating by amount
sub _nodes_modulate {
    my ($self, $nodes, $amount) = @_;
    my @nodes = @$nodes;   #make a copy
    my $value;
    
    if (@nodes) {
        if ($nodes[0]->kind eq 'NUMBER') {
            $value = $nodes[0]->value;
            shift @nodes;
        } else  {
            for (my $i = 1; $i < @nodes; $i++) {
                if ($nodes[$i]->kind eq 'NUMBER' and 
                    $nodes[$i-1]->value ~~ ['+', '-']) {
                    #[+-]Number
                    $value = $nodes[$i-1]->value . $nodes[$i]->value;
                    splice @nodes, $i-1, 2;
                    last;
                }
            }
        }
        $value .= $amount;
        $value = eval($value);
        if ($value < 0) {
            if (@nodes) {
                push @nodes, new Node::Arithmetic::('-');
                push @nodes, new Node::Number::($value * -1);
            } else {
                push @nodes, new Node::Number::($value);
            }

        } elsif ($value > 0) {
            push @nodes, new Node::Arithmetic::('+') if @nodes;
            push @nodes, new Node::Number::($value);
        } else {
            push @nodes, new Node::Number::($value) unless @nodes;
        }
    }
    return [@nodes];
}


# returns a modified 'exp' list, by subtracting 1
sub _nodes_minus_one {
    my ($self, $nodes) = @_;
    return $self->_nodes_modulate($nodes, '-1');
}

# returns a modified 'exp' list, by adding 1
sub _nodes_plus_one {
    my ($self, $nodes) = @_;
    return $self->_nodes_modulate($nodes, '+1');
}

# returns prev,next stored types
sub get_sibling_types {
    my ($self) = @_;
    my $prev = ($self->prev && $self->prev->type->kind);
    my $next = ($self->next && $self->next->type->kind);
    return ($prev, $next)
}


1;