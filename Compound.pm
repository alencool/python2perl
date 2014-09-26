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
    my ($self, $value) = @_;
    $self->is_compound(TRUE);
    $self->complete(FALSE);
}

sub _on_event_add_child {
    my ($self, $node) = @_;
    my $add_child = TRUE;
    if ($node->kind eq 'EXPRESSION' and $node->is_leaf) {
        # i.e. empty expression
        my $peg = $self->children->get_peg(0);
        if (@$peg == 1) {
            # first item is conditional
            # dont want one statement to be empty
            my $add_child = FALSE;
        }
    }
    return $add_child;
}

sub kind {
    return 'COMPOUND';
}

sub to_string {
    my ($self, $name) = @_;
    my $peg = $self->children->get_peg(0);
    my @strings;
    my $expr = shift @$peg;
    my $conditional = $expr->to_string_as_conditional;
    my $indent = $self->indent;
    $name = "Compound" unless defined $name;
    push @strings, sprintf("$indent%s%s {", $name, $conditional);
    for my $child (@$peg) {
        push @strings, $child->to_string;
    }
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
#-----------------------------------------------------------------------
package Node::Elif;
use base 'Node::Compound';

sub to_string {
    my ($self) = @_;
    return $self->SUPER::to_string('elsif');
}
#-----------------------------------------------------------------------
package Node::Else;
use base 'Node::Compound';

sub to_string {
    my ($self) = @_;
    return $self->SUPER::to_string('else');
}
#-----------------------------------------------------------------------
package Node::For;
use base 'Node::Compound';

sub to_string {
    my ($self) = @_;
    return $self->SUPER::to_string('for');
}

#-----------------------------------------------------------------------
package Node::While;
use base 'Node::Compound';

sub to_string {
    my ($self) = @_;
    return $self->SUPER::to_string('while');
}

#-----------------------------------------------------------------------
package Node::Def;
use base 'Node::Compound';

sub to_string {
    my ($self) = @_;
    return $self->SUPER::to_string('sub');
}

#-----------------------------------------------------------------------

package Node::Code;
use Constants;
use base 'Node::Compound';

sub _on_event_add_child {
    return TRUE;
}

sub to_string {
    my ($self) = @_;
    my $peg = $self->children->get_peg(0);
    my @strings;
    for my $child (@$peg) {
        push @strings, $child->to_string;
    }

    return join("\n", @strings);
}


1;