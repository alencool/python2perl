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
use Type;
#-----------------------------------------------------------------------
#  ___ _                   _     _  _         _        
# | __| |___ _ __  ___ _ _| |_  | \| |___  __| |___ ___
# | _|| / -_) '  \/ -_) ' \  _| | .` / _ \/ _` / -_|_-<
# |___|_\___|_|_|_\___|_||_\__| |_|\_\___/\__,_\___/__/ 
#
#-----------------------------------------------------------------------
package Node::Element;
use Constants;
use base 'Node';

sub infer_type {
    my ($self) = @_;
    $self->type(new Type('NUMBER'));
    return $self->type;
}

#-----------------------------------------------------------------------

package Node::Arithmetic;
use base 'Node::Element';

sub kind {
    return 'ARITHMETIC';
}

sub to_string {
    my ($self) = @_;
    my $str = $self->value;
    my ($prev, $next) = $self->get_sibling_types;
    if ('STRING' ~~ [$prev, $next]) {
        $str = 'x' if ($str eq '*');
        $str = '.' if ($str eq '+');
    } 
    return $str;
}

#-----------------------------------------------------------------------
package Node::Assignment;
use base 'Node::Element';

sub kind {
    return 'ASSIGNMENT';
}

#-----------------------------------------------------------------------
package Node::Bitwise;
use base 'Node::Element';

sub kind {
    return 'BITWISE';
}

#-----------------------------------------------------------------------
package Node::Comparison;
use base 'Node::Element';

sub _init {
    my ($self, $value) = @_;
    $self->value('!=') if ($value eq '<>');
}

sub to_string {
    my ($self) = @_;
    my $str = $self->value;
    my ($prev, $next) = $self->get_sibling_types;

    if ('STRING' ~~ [$prev, $next]) {
        given ($str) {
            when ('<')  { $str = 'lt' }
            when ('>')  { $str = 'gt' }
            when ('<=') { $str = 'le' }
            when ('>=') { $str = 'ge' }
            when ('==') { $str = 'eq' }
            when ('!=') { $str = 'ne' }
        }
    } 
    return $str;
}


sub kind {
    return 'COMPARISON';
}

#-----------------------------------------------------------------------
package Node::Closer;
use base 'Node::Element';

sub kind {
    return 'CLOSER';
}

#-----------------------------------------------------------------------
package Node::Encloser;
use Constants;
use base 'Node::Element';

sub _init {
    my ($self) = @_;
    $self->complete(FALSE);
}

sub _on_event_add_child {
    my ($self, $node) = @_;
    my $add_child = FALSE;
    given ($node->kind) {
        when ('COMA_SEPERATOR') { $self->children->new_list }
        when ('COLN_SEPERATOR') { $self->children->new_list }
        when ('CLOSER')         { $self->complete(TRUE) }
        default                 { $add_child = TRUE }
    }

    return $add_child;
}

sub to_string {
    my ($self) = @_;
    return sprintf("%s", $self->join_children());
}

sub infer_type {
    my ($self, $type_manager) = @_;
    my ($type, $multi);
    $multi = $self->children;
    $type = $self->infer_type_from_multilist($type_manager, $multi);

    return $type;

}

#-----------------------------------------------------------------------
package Node::Dict;
use base 'Node::Encloser';

sub kind {
    return 'DICT';
}

sub to_string {
    my ($self, $scalar) = @_;
    my $str = $self->join_children(' => ',', ');
    if ($self->parent->kind ~~ ['LIST', 'DICT', 'TUPLE'] or $scalar) {
        $str = qq/{$str}/;
    } else {
        $str = qq/($str)/;
    }
    return $str;
}

sub infer_type {
    my ($self, $type_manager) = @_;
    my $type;
    my $dict = {};
    my @lists = $self->children->get_lists;
    my $iter = sub { return shift @lists };

    for (;;) {
        my $key = $iter->();
        my $value = $iter->();
        last unless defined $value;
        if ($key->[0]->kind ~~ ['NUMBER', 'STRING']) {
            $key = $key->[0]->value || '_';
            $type = $self->infer_type_from_list($type_manager, @$value);
            $dict->{$key} = $type;
        }
    }
    $type = new Type($dict);
    return $type;
}


#-----------------------------------------------------------------------
package Node::List;
use base 'Node::Encloser';

sub kind {
    return 'LIST';
}

sub to_string {
    my ($self, $scalar) = @_;
    my $str = $self->join_children;
    if ($self->parent->kind ~~ ['LIST', 'DICT', 'TUPLE'] or $scalar) {
        $str = qq/[$str]/;
    } else {
        $str = qq/($str)/;
    }
    return $str;
}
#-----------------------------------------------------------------------
package Node::Tuple;
use base 'Node::Encloser';

sub kind {
    return 'TUPLE';
}

#-----------------------------------------------------------------------
package Node::Subscript;
use base 'Node::Encloser';
Node::Subscript->mk_accessors(qw(caller));

sub set_caller {
    my ($self, $caller) = @_;
    $self->caller($caller);
    $caller->parent($self);
}

sub kind {
    return 'SUBSCRIPT';
}

sub to_string {
    my ($self) = @_;
    my $str = $self->join_children(':');
    #TODO slicing in perl involves the range operator ..
    # also displaying this may be different if argv is next to it!
    $str = sprintf("%s[%s]", $self->caller->to_string, $str);
    return $str;
}

sub infer_type {
    my ($self, $type_manager) = @_;
    my $type;
    #TODO


    return $type;
}

#-----------------------------------------------------------------------
package Node::Call;
use Constants;
use base 'Node::Element';

sub kind {
    return 'FUNCTION_CALL';
}

sub _on_event_add_child {
    my ($self, $node) = @_;
    my $add_child = FALSE;

    if ($node->kind eq 'COMA_SEPERATOR') {
        $self->children->new_list; 
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

#     my $list = $self->children->get_list(0);
#     my @strings;
#     my $expr = shift @$list;
#     print $expr;
#     my $conditional = $expr->join_children;
#     my $indent = $self->indent;
#     push @strings, sprintf("$indent%s%s {", $name, $conditional);
#     for my $child (@$list) {
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
    $caller->parent($self);
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
use base 'Node::Element';

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
package Node::In;
use base 'Node::Element';

sub kind {
    return 'IN';
}

#-----------------------------------------------------------------------
package Node::Logical;
use base 'Node::Element';

sub kind {
    return 'LOGICAL';
}

#-----------------------------------------------------------------------
package Node::Number;
use base 'Node::Element';

sub kind {
    return 'NUMBER';
}

#-----------------------------------------------------------------------
package Node::Seperator;
use base 'Node::Element';

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

sub infer_type {
    my ($self, $type_manager) = @_;
    $self->type(new Type('STRING'));
    return $self->type;
}

#-----------------------------------------------------------------------
package Node::Indent;
use base 'Node';

sub kind {
    return 'INDENT';
}

#-----------------------------------------------------------------------
package Node::Whitespace;
use base 'Node';

sub kind {
    return 'WHITESPACE';
}

#-----------------------------------------------------------------------
package Node::Comment;
use base 'Node';

sub kind {
    return 'COMMENT';
}

#-----------------------------------------------------------------------
# Indicates an unrecognised token
package Node::Error;
use base 'Node';

sub kind {
    return 'ERROR';
}

1;