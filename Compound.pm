#
#  Compound.pm
#  Defines is a set of classes that represent compound statments in 
#  python for use in the creation of a tree.
#
#  Created by Alen Bou-Haidar on 26/09/14, edited 6/10/14
#


use strict;
use warnings;
use feature 'switch';

#-----------------------------------------------------------------------
#   ___                                  _   _  _         _        
#  / __|___ _ __  _ __  ___ _  _ _ _  __| | | \| |___  __| |___ ___
# | (__/ _ \ '  \| '_ \/ _ \ || | ' \/ _` | | .` / _ \/ _` / -_|_-<
#  \___\___/_|_|_| .__/\___/\_,_|_||_\__,_| |_|\_\___/\__,_\___/__/
#                |_|                                               
#-----------------------------------------------------------------------
package Node::Compound;
use Constants;
use base 'Node';

sub _init {
    my ($self) = @_;
    $self->is_compound(TRUE);
    $self->complete(FALSE);
}

sub infer_type {
    my ($self, $type_manager) = @_;
    if (not $type_manager) {
        $type_manager = new Type::Manager;
    }
    my $list = $self->children->get_list(0);
    for my $node (@$list) {
        $node->infer_type($type_manager);
    }
}


sub _on_event_add_child {
    my ($self, $node) = @_;
    my $add_child = TRUE;

    if ($self->is_leaf) {
        # comment can't be added directely to compounds
        # since they on accept statments 
        $self->comment($node->comment);
    } elsif ($node->kind eq 'EXPRESSION' and 
             $node->is_leaf              and
             $self->children->is_single) {
            # first item is conditional
            # dont want one statement to be empty
            $add_child = FALSE;
    }
    return $add_child;
}

sub to_string {
    my ($self) = @_;
    my (@strings, $str);    
    push @strings, $self->_header(lc($self->kind));
    push @strings, $self->_body;
    push @strings, $str if $str = $self->_endbody;
    return join("\n", @strings);
}


sub _header {
    my ($self, $name) = @_;
    my $ exp = $self->children->get_single->to_string_conditional;
    return $self->indent.$name.$exp.' {'.$self->comment;
}

sub _body {
    my ($self) = @_;
    my $list = $self->children->get_list(0);
    my @strings = map {$_->to_string} @$list;
    shift @strings;
    return join("\n", @strings);
}

sub _endbody {
    my ($self) = @_;
    return $self->indent.'}';
}

#-----------------------------------------------------------------------
package Node::If;
use base 'Node::Compound';

sub _endbody {
    my ($self) = @_;
    my $has_end = !($self->next and $self->next->kind ~~ ['ELSE', 'ELSIF']);
    return  ($has_end? $self->indent.'}' : '');
}

#-----------------------------------------------------------------------
package Node::Elsif;
use base 'Node::If';

sub _header {
    my ($self, $name) = @_;
    my $exp = $self->children->get_single->to_string_conditional;
    return $self->indent.'} '.$name.$exp.' {'.$self->comment;
}

#-----------------------------------------------------------------------
package Node::Else;
use base 'Node::Elsif';

#-----------------------------------------------------------------------
package Node::For;
use base 'Node::Compound';
use Constants;
# python:   for TARGET in ITERABLE:
# perl:     foreach my TARGET (LIST) { [#comment]
sub _header {
    my ($self, $name) = @_;
    my $exp = $self->children->get_single;
    my $exp_lst = $exp->children->get_list(0);
    my $target = $exp_lst->[0]->to_string('TARGET');
    my $iter = $exp_lst->[-1];
    my ($str, $list);

    given ($iter->subkind) {
        when ('ARGV')           { $list = '@ARGV' }
        when ('STDIN')          { $list = '<STDIN>'}
        when ('SUBSCRIPT')      { $list = $iter->to_string('EXPAND')}
        when ('IDENTIFIER')     { $list = $iter->to_string('EXPAND')}
        when ('LIST')           { $list = $iter->to_string('EXPAND')}
        default                 { $list = $iter->to_string }
    }
    if ($iter->subkind eq 'CALLOPEN') {
        $str = $self->indent.$iter->to_string().";\n";
        $str .= $self->indent."while ($target = <F>) {";
    } elsif ($iter->subkind eq 'CALLFILEINPUT') {
        $str = $self->indent."while ($target = <>) {";
    } else {
        $str = $self->indent."foreach $target ($list) {";
    }

    return $str.$self->comment;
}

sub _endbody {
    my ($self) = @_;
    my $str = $self->indent."}";    
    my $iter = $self->children->get_list(0)->[-1];
    if ($iter->subkind eq 'CALLOPEN') {
        $str .= "\n".$self->indent."close(F);";
    } 
    return $str;
}

sub infer_type {
    my ($self, $type_manager) = @_;
    my $exp = $self->children->get_single;
    my $exp_lst = $exp->children->get_list(0);
    my $target = $exp_lst->[0];
    my $iter = $exp_lst->[-1];
    my $target_is_str = FALSE;
    $iter->infer_type($type_manager);
    given ($iter->subkind) {
        when ('ARGV')           { $target_is_str = TRUE }
        when ('STDIN')          { $target_is_str = TRUE }
        when ('CALLOPEN')       { $target_is_str = TRUE }
        when ('CALLFILEINPUT')  { $target_is_str = TRUE }
        when ('SUBSCRIPT')      { $target_is_str = 
                         ($iter->type->kind eq 'STRING')}
        when ('IDENTIFIER')     { $target_is_str = 
                         ($iter->type->kind eq 'STRING')}
        when ('LIST')           { $target_is_str = 
           ($iter->type->get_query(0)->kind eq 'STRING')}
    }
    if ($target_is_str) {    
        $target->imply_type($type_manager, new Type('STRING'));
    }
    $self->SUPER::infer_type($type_manager);
}

#-----------------------------------------------------------------------
package Node::While;
use base 'Node::Compound';

#-----------------------------------------------------------------------
package Node::Sub;
use base 'Node::Compound';
use Constants;
Node::Sub->mk_accessors(qw(param_seq local_seq return_type));

sub _init {
    my ($self) = @_;
    $self->SUPER::_init;
    $self->return_type(undef);
}

# register request for param types 
sub infer_type {
    my ($self, $type_manager) = @_;
    my ($name) = $self->_get_names;
    $type_manager->register_func($name, $self);
}

# attempt to deduce its representive type
sub infer_type_params {
    my ($self, $type_manager, @param_types) = @_;

    if (not defined $self->return_type) {    
        my ($name, @params) = $self->_get_names;
        my @param_seq;
        $type_manager->push_frame;
        # set types for parameters in the new frame
        for my $i (0..$#params) {
            $type_manager->set($params[$i], $param_types[$i]);
            push @param_seq, ($params[$i], $param_types[$i]->kind);
        }
        $self->param_seq(\@param_seq); 
        my @exprs = @{$self->children->get_list(0)};
        shift @exprs;  # remove function parameters
        $self->infer_from_list(\@exprs);
        my ($type, $seq) = $type_manager->pop_frame;
        
        $self->return_type($type || new Type('NUMBER'));
        $self->local_seq($seq);
    }

    return $self->return_type;
}

# returns a list consisting of function name and parameter names
sub _get_names {
    my ($self) = @_; 
    my @names;
    my $func = $self->children->get_single->children->get_single; 
    push @names, $func->value; # the function name
    for my $list ($func->children->get_lists) {
        push @names, $list->[0]->value if @$list > 0; # the params
    }
    return @names;
}

sub _header {
    my ($self) = @_;
    my ($name, @params) = $self->_get_names;
    my $str = $self->indent."sub $name {".$self->comment;
    my $indent = $self->indent."    ";
    my (%declared, $kind);
    
    # declare parameters
    my @param_seq = @{$self->param_seq};
    while (@param_seq) {
        $name = shift @param_seq;
        $kind = shift @param_seq;
        $declared{$name}{$kind} = 1;
        given ($kind) {
            when ('HASH')  { $str .= "\n$indent"."my %$name = %{shift(\@_)};" }
            when ('ARRAY') { $str .= "\n$indent"."my \@$name = \@{shift(\@_)};" }
            default        { $str .= "\n$indent"."my \$$name = shift(\@_);" }
        }
    }

    # decalar locals
    my @local_seq = @{$self->local_seq};
    while (@local_seq) {
        $name = shift @local_seq;
        $kind = shift @local_seq;
        next if ($kind ~~ $declared{$name});
        $declared{$name}{$kind} = 1;
        given ($kind) {
            when ('HASH')  { $str .= "\n$indent"."my %$name;" }
            when ('ARRAY') { $str .= "\n$indent"."my \@$name;" }
            default        { $str .= "\n$indent"."my\$$name;" }
        }
    }

    return $str;
}

sub _body {
    my ($self) = @_;
    my @list = @{$self->children->get_list(0)};
    shift @list;
    my @strings = map {$_->to_string} @list;
    return join("\n", @strings);
}

#-----------------------------------------------------------------------

package Node::Code;
use Constants;
use base 'Node::Compound';

sub _init {
    my ($self, $node) = @_;
    $self->SUPER::_init;
    $node = new Node::Expression;
    $node->comment(qq'#!/usr/bin/perl -w');
    $self->children->append($node);
}

sub _on_event_add_child {
    my ($self, $node) = @_;
    my $okay_to_add = TRUE;
    if ($self->children->is_single) {
        if ($node->is_leaf and $node->comment =~ /#!/) {
            $okay_to_add = FALSE;
        }
    } 
    return $okay_to_add;
}

sub to_string {
    my ($self) = @_;
    my $list = $self->children->get_list(0);
    my @strings = map {$_->to_string} @$list;
    return join("\n", @strings);
}


1;