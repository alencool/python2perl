#
#  Compound.pm
#  Defines is a set of classes that represent compound statments in 
#  python for use in the creation of a tree.
#
#  Created by Alen Bou-Haidar on 26/09/14, edited 26/9/14
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

sub _kind {
    return 'COMPOUND';
}

sub to_string {
    my ($self, $name) = @_;
    my $list = $self->children->get_list(0);
    my @strings;
    my $exp = $list->[0]->to_string_conditional;
    my $indent = $self->indent;
    @strings = map {$_->to_string} @$list;
    my $header = sprintf("$indent%s%s {%s", $name, $exp, $self->comment);
    splice @strings, 0,1, $header;
    push @strings, "$indent}";
    return join("\n", @strings);
}

#-----------------------------------------------------------------------
package Node::If;
use base 'Node::Compound';

sub to_string {
    my ($self) = @_;
    return $self->SUPER::to_string('if');
}

sub _kind {
    return 'IF';
}

#-----------------------------------------------------------------------
package Node::Elif;
use base 'Node::Compound';

sub to_string {
    my ($self) = @_;
    return $self->SUPER::to_string('elsif');
}

sub _kind {
    return 'ELIF';
}

#-----------------------------------------------------------------------
package Node::Else;
use base 'Node::Compound';

sub to_string {
    my ($self) = @_;
    return $self->SUPER::to_string('else');
}

sub _kind {
    return 'ELSE';
}

#-----------------------------------------------------------------------
package Node::For;
use base 'Node::Compound';

sub to_string {
    my ($self) = @_;
    return $self->SUPER::to_string('foreach');
}

sub _kind {
    return 'FOR';
}

#-----------------------------------------------------------------------
package Node::While;
use base 'Node::Compound';

sub to_string {
    my ($self) = @_;
    return $self->SUPER::to_string('while');
}

sub _kind {
    return 'WHILE';
}

#-----------------------------------------------------------------------
package Node::Def;
use base 'Node::Compound';

sub to_string {
    my ($self) = @_;
    return $self->SUPER::to_string('sub');
}

sub _kind {
    return 'DEF';
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