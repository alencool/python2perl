#
#  Simple.pm
#  Defines is a set of classes that represent simple statments in 
#  python for use in the creation of a tree.
#
#  Created by Alen Bou-Haidar on 26/09/14, edited 5/10/14
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
    my ($self) = @_;
    my $args = ';';
    my $name = lc($self->kind);
    if (not $self->is_leaf){
        $args = sprintf " %s;", $self->join_children;
    } 
    return $self->indent.$name.$args.$self->comment;
}

#-----------------------------------------------------------------------
package Node::Invisible;
use base 'Node::Simple';

sub to_string {
    my ($self) = @_;
    return $self->comment;
}

#-----------------------------------------------------------------------
package Node::Expression;
use Constants;
use base 'Node::Simple';
Node::Expression->mk_accessors(qw(targets assignment));

# adds child the last open tuple, if none then creates it
sub _init {
    my ($self) = @_;
    $self->SUPER::_init;
    $self->targets([]);
    $self->assignment('');
}

sub infer_type {
    my ($self, $type_manager) = @_;

    # get type from right most multilist
    $self->SUPER::infer_type($type_manager);

    # infer and assign types for targets
    $self->_assign_types($type_manager) if $self->assignment;

    return $self->type;
}

sub _assign_types {
    my ($self, $type_manager) = @_;
    my (@types, @targets, $node, $type);

    @targets = @{$self->targets};

    # get types
    if ($self->type->kind eq 'ARRAY' and $targets[-1]->list_count > 1) {
        @types = @{$self->type->data};
    } else {
        @types = ($self->type->data);
    }
    
    # assign types to each target
    if ($self->assignment eq '=') {
        for my $target (@targets) {
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
    map {$self->infer_from_multilist($type_manager, $_)} @targets;

}

sub to_string {
    my ($self) = @_;
    my @strings;    # list of components to make up the expression
    my $string;     # final expression
    my $uno_target; # contains the first left most target node
    my $uno_value;  # contains single value node if only one
    my $is_single;  # true if only a single value
    my $calls = ['CALLOPEN', 'CALLMATCH', 'CALLSEARCH', 'CALLSUB'];
    my @targets = @{$self->targets};
    for my $target (@targets) {
        $string = $self->join_multilist($target, 'TARGET');
        $string = qq/($string)/ if ($target->list_count > 1);
        push @strings, $string; 
    }
    if (@targets) {
        $uno_target = $targets[-1]->get_single;
        $uno_value = $self->children->get_single;
        $is_single = $self->children->is_empty;
        if ($is_single and $targets[-1]->is_single and 
            $uno_target->kind ne 'SUBSCRIPT') {
            $string = $self->join_children('EXPAND');
        } else {
            $string = $self->join_children;
        }
        $string = qq/($string)/ if ($self->children->list_count > 1);
        push @strings, $string;
    }


    given ($self->assignment) {
        when ('')   {
            $string = $self->join_children;
        }
        when ('=')  {
            if ($uno_value->subkind ~~ $calls) {
                my $handle = $targets[-1]->get_single;
                $string = $uno_value->to_string($handle);
            } else {
                $string = join(' = ', @strings);
            }
        }
        when ('*=') {
            if ($uno_target->type->kind eq 'STRING') {
                $string = join(' x= ', @strings);
            } else {
                $string = join(' *= ', @strings);
            }
        }
        when ('+=') {
            if ($uno_target->type->kind eq 'STRING') {
                $string = join(' .= ', @strings);
            } elsif  ($uno_target->type->kind eq 'ARRAY') {
                $string = $self->join_multilist($targets[-1], 'EXPAND');
                $string = "push $string, ";
                $string .= $self->join_children('EXPAND');
            } elsif ($is_single and $uno_value->value eq '1' ) {
                $string = $strings[0]."++";
            } else {
                $string = join(' += ', @strings);
            }
        }
        when ('-=') {
            if ($is_single and $uno_value->value eq '1' ) {
                $string = $strings[0]."--";
            } else {
                $string = join(' -= ', @strings);
            }
        }
        default     {
            $string = join(' '.$self->assignment.' ', @strings);
        }

    }

    $string = $self->indent.$string.';' if $string;
    $string .= $self->comment;
    
    return $string;
}

# return true if targets exist
sub _has_targets {
    my ($self) = @_;
    return (@{$self->targets} > 0);

}

# output format suitable for a condiional statement
sub to_string_conditional {
    my ($self) = @_;
    my ($multi, $str);
    $str = $self->join_children;
    $str = qq/ ($str)/ if $str;
    return $str;
}

sub _on_event_add_child {
    my ($self, $node) = @_;
    my $add_child = FALSE;
    if ($node->kind eq 'ASSIGNMENT') {
        # transformed to assignment statement, extract targets
        $self->_peel_multilist;
        $self->children->chomp;
        push @{$self->targets}, $self->children;
        $self->children(new MultiList);
        $self->assignment($node->value);
    } elsif ($node->kind eq 'COMA_SEPERATOR') {
        # new list for each target expression
        $self->children->new_list;
    } elsif ($node->kind ~~ ['STMT_SEPERATOR', 'COLN_SEPERATOR']){
        # statement completion
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
use Constants;

sub to_string {
    my ($self) = @_;
    $self->_peel_multilist;
    my @args;
    my @strings;
    my $new_line = TRUE;
    my $str_buffer = '';
    my @expressions = $self->children->get_lists;
    my $interpolatable = ['NUMBER', 'STRING', 'SUBSCRIPT', 'IDENTIFIER'];


    my $push_buffer = sub {
        if ($str_buffer) {
            push @args, new Node::String::($str_buffer);
            $args[-1]->subkind('PLAIN');
            $str_buffer = '';
        }
    };

    # interpolate arguments
    for my $expr (@expressions) {
        my $is_single = (@$expr == 1);
        my $is_empty = (@$expr == 0);

        if ($is_single and $expr->[0]->kind ~~ $interpolatable) {
            $str_buffer .= ' ' if @args || $str_buffer;
            if ($expr->[0]->kind ~~ 'STRING') {
                $str_buffer .= $expr->[0]->value;
            } else {
                $str_buffer .= $expr->[0]->to_string('EXPAND');
            }
        } elsif ($is_single and $expr->[0]->kind ~~ 'SPRINTF') {
            $push_buffer->();
            push @args, $expr->[0];
        } elsif ($is_empty) {
            $str_buffer .= ' ';
            $new_line = FALSE;
        } else {
            $push_buffer->();
            push @args, new Node::String::($self->join_nodes($expr));
        }
    }
    $str_buffer .= "\\n" if $new_line;
    $push_buffer->();

    # write print/printf statments
    push @strings, '';
    while (@args) {
        my $node = shift @args;
        if ($node->subkind eq 'PLAIN') {
            if (!$strings[-1]) {
                $strings[-1] .= $self->indent."print(";
                $strings[-1] .= $node->to_string ;
            } else {
                $strings[-1] .= ", ";
                $strings[-1] .= $node->to_string ;
            }
        } elsif ($node->kind eq 'STRING') {
            if (!$strings[-1]) {
                $strings[-1] .= $self->indent."print(";
                $strings[-1] .= $node->value ;
            } else {
                $strings[-1] .= ", ";
                $strings[-1] .= $node->value ;
            }
        } elsif ($node->kind eq 'SPRINTF') {
            while (@args and $args[0]->subkind eq 'PLAIN') {
                my $success = $node->append_to_fmt($args[0]->value);
                if ($success) {
                    shift @args;
                } else {
                    last;
                }
            }
            if ($strings[-1]) {
                $strings[-1] .= ");";
                push @strings, '';
            }
            $strings[-1] .= $self->indent.$node->to_string.";";
            substr $strings[-1], 0, 1, "";
            push @strings, '';
        }
    }

    # complete statement or remove trailing ""
    if ($strings[-1]) {
        $strings[-1] .= ");";
    } else {
        pop @strings;
    }
    # write comment
    $strings[-1] .= $self->comment;

    # join statments with new line
    $str_buffer = join("\n", @strings);

    return $str_buffer;


}

#-----------------------------------------------------------------------
package Node::Return;
use base 'Node::Simple';

#-----------------------------------------------------------------------
package Node::Last;
use base 'Node::Simple';
#-----------------------------------------------------------------------
package Node::Next;
use base 'Node::Simple';

1;