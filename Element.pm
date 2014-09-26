#
#  Element.pm
#  Defines is a set of classes that represent elemental parts in 
#  python for use in the creation of a tree.
#
#  Created by Alen Bou-Haidar on 26/09/14, edited 26/9/14
#

use strict;
use warnings;
use feature 'switch';

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

sub to_string {
    my ($self) = @_;
    #TODO !
    # check type of siblings
    # multiplication of string and numbeer (x)
    # concatination of strings is          (.)
    # concatination of Lists .. more compex

    return $self->value;
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
package Node::Closer;
use base 'Node';

sub kind {
    return 'CLOSER';
}

#-----------------------------------------------------------------------
package Node::Encloser;
use Constants;
use base 'Node';

sub _init {
    my ($self) = @_;
    $self->complete(FALSE);
}

sub _on_event_add_child {
    my ($self, $node) = @_;
    my $add_child = FALSE;

    given ($node->kind) {
        when ('COMA_SEPERATOR') { $self->children->new_peg }
        when ('COLN_SEPERATOR') { $self->children->new_peg }
        when ('CLOSER')         { $self->complete(TRUE) }
        default                 { $add_child = TRUE }
    }

    return $add_child;
}

sub to_string {
    my ($self) = @_;
    return sprintf("(%s)", $self->join_children());

#-----------------------------------------------------------------------
package Node::Dict;
use base 'Node::Encloser';

sub kind {
    return 'DICT';
}

#-----------------------------------------------------------------------
package Node::Tuple;
use base 'Node::Encloser';

sub kind {
    return 'TUPLE';
}

#-----------------------------------------------------------------------
package Node::List;
use base 'Node::Encloser';

sub kind {
    return 'LIST';
}

#-----------------------------------------------------------------------
package Node::Subscript;
use base 'Node::Encloser';
Node::Subscript->mk_accessors(qw(caller));

sub set_caller {
    my ($self, $caller) = @_;
    $self->caller($caller);
}

sub kind {
    return 'SUBSCRIPT';
}

sub to_string {
    my ($self) = @_;
    #TODO slicing in perl involves the range operator ..
    # also displaying this may be different if argv is next to it!


    return sprintf("[%s]", $self->join_children(':',''));
}

#-----------------------------------------------------------------------
package Node::Call;
use Constants;
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

# sub to_string {
#     my ($self, $name) = @_;
#     $name = $self->value unless $name;

#     my $peg = $self->children->get_peg(0);
#     my @strings;
#     my $expr = shift @$peg;
#     print $expr;
#     my $conditional = $expr->join_children;
#     my $indent = $self->indent;
#     push @strings, sprintf("$indent%s%s {", $name, $conditional);
#     for my $child (@$peg) {
#         push @strings, $child->to_string;
#     }
#     push @strings, "$indent}";
#     return join("\n", @strings);
# }

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

1;