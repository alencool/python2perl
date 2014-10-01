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

sub _init {
    my ($self, $value) = @_;
    $self->value('/') if ($value eq '//');
}


sub _kind {
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

sub _init {
    my ($self, $value) = @_;
    $self->value('/=') if ($value eq '//=');
}

sub _kind {
    return 'ASSIGNMENT';
}

#-----------------------------------------------------------------------
package Node::Bitwise;
use base 'Node::Element';

sub _kind {
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


sub _kind {
    return 'COMPARISON';
}

#-----------------------------------------------------------------------
package Node::Closer;
use base 'Node::Element';

sub _kind {
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

sub _kind {
    return 'DICT';
}

sub to_string {
    my ($self, $as_scalar) = @_;
    my $str = $self->join_children(' => ',', ');
    if (not defined $as_scalar) {
        $as_scalar = ($self->parent->kind ~~ ['LIST','DICT','TUPLE']);
    }
    if ($as_scalar) {
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

sub _kind {
    return 'LIST';
}

sub to_string {
    my ($self, $as_scalar) = @_;
    my $str = $self->join_children;
    if (not defined $as_scalar) {
        $as_scalar = ($self->parent->kind ~~ ['LIST','DICT','TUPLE']);
    }
    if ($as_scalar) {
        $str = qq/[$str]/;
    } else {
        $str = qq/($str)/;
    }
    return $str;
}

#-----------------------------------------------------------------------
package Node::Flat;
use base 'Node::List';
use Constants;

sub _kind {
    # special flatten list type of container
    return 'FLAT';
}

sub _on_event_add_child {
    my ($self, $node) = @_;
    if (!$self->is_leaf) {
        $self->children->new_list;
    }
    return TRUE;
}

#-----------------------------------------------------------------------
package Node::Tuple;
use base 'Node::Encloser';

sub _kind {
    return 'TUPLE';
}

sub to_string {
    my ($self) = @_;
    return sprintf("(%s)", $self->join_children());
}

#-----------------------------------------------------------------------
package Node::Subscript;
use base 'Node::Encloser';
use Constants;
Node::Subscript->mk_accessors(qw(caller));

sub set_caller {
    my ($self, $caller) = @_;
    $self->caller($caller);
    $caller->parent($self);
}

sub _kind {
    return 'SUBSCRIPT';
}

sub to_string {
    my ($self, $as_scalar) = @_;
    my $cl_kind   = $self->caller->kind;
    my $cl_name  = '$'.$self->caller->value;
    my $cl_scalar = $self->caller->to_string(TRUE);
    my $cl_nonsca = $self->caller->to_string(FALSE);
    my $signature = $self->_get_signature;
    my $str;
    if (not $signature) {
        $str = $as_scalar ? $cl_scalar : $cl_nonsca;
    } elsif ($self->is_slice) 
        $str = "$cl_nonsca[$signature]";
        $str = "\@{$cl_scalar}[$signature]" if $cl_kind eq 'SUBSCRIPT';
        $str = "[$str]" if ($as_scalar);
    } else { 
        if ($caller->type->kind eq 'HASH') {
            $str = "$cl_scalar{$signature}";
            $str = "$cl_scalar->{$signature}" if $cl_kind eq 'DICT';
            $str = "$cl_name{$signature}" if $cl_kind eq 'IDENTIFIER';
        } else {
            $str = "$cl_scalar[$signature]";
            $str = "$cl_nonsca[$signature]" if $cl_kind eq 'LIST';
            $str = "$cl_name[$signature]" if $cl_kind eq 'IDENTIFIER';
        }
        if (not $as_scalar) {
            given ($self->type->kind) {
                when ('ARRAY')  { $str = "\@{$str}" }
                when ('HASH')   { $str = "%{$str}" }
            }
        }
    }


    return $str;
}

sub _get_signature {
    my ($self) = @_;
    my $python_sig = $self->join_children(':');
    my $perl_sig;

    # [i:j] with index k such that i <= k < j. 
    # => i .. j-1
    my $i = $self->children->get_list(0);
    my $j = $self->children->get_list(1);

    # consider no i, and shifted j
    push @$i, new Node::Number(0) unless @$i > 0;
    $j = $self->_nodes_minus_one($j) if $j;

    if ($self->caller->kind eq 'IDENTIFIER' and  
        $self->caller->value eq 'ARGV') {
        # consider the case of ARGV
        if ($python_sig eq '1:'){
            # special case where we can drop the slice
            $perl_sig = '';
        } else {
            # perls argv missing $0, so -1 to i and j
            $i = $self->_nodes_minus_one($i);
            $j = $self->_nodes_minus_one($j) if $j;
            $perl_sig  = $self._join_nodes($i, ' ');
            $perl_sig .= '..' if $j;
            $perl_sig .= $self._join_nodes($j, ' ') if $j;
            $perl_sig .= "\$#ARGV" if $j and @$j == 0;
        }
    } else {
        # all other types of slices and keys
        $perl_sig  = $self._join_nodes($i, ' ');
        $perl_sig .= '..' if $j;
        $perl_sig .= $self._join_nodes($j, ' ') if $j;
        if ($j and @$j == 0) {
            # only really take the case of identifier or subscript
            my $cl_str = $self->caller->to_string(TRUE);
            if ($self->caller->kind eq 'IDENTIFIER') {
                $cl_str =~ s/\$/\$#/;
                $perl_sig .= $cl_str;
            } else {
                $perl_sig .= "\$#{$cl_str}";
            }
        }
    }

    if ($python_sig eq ':') {
        # no arguments given
        $perl_sig = '';
    }

    return $perl_sig;
}


sub infer_type {
    my ($self, $type_manager) = @_;
    my $caller_type = $self->caller->infer_type($type_manager);
    my $key = $self->_get_key;
    my $type = $caller_type->get_query($key);
    $self->type($type);
    return $type;
}

# get the subscription key
sub _get_key {
    my ($self) = @_;
    my $key = $self->_join_nodes($self->children->get_list(0), ' ');
    $key = '0' unless $key;
    return $key;
}

sub is_slice {
    my ($self) = @_;
    return ($self->children->list_count > 1);
}

sub imply_type {
    my ($self, $type_manager, $type) = @_;
    my $caller_type = $self->caller->type;
    my $key = $self->_get_key;
    if (!$self->is_slice) {
        $self->type($type);
        $caller_type->set_query($key, $type);
    }
}

#-----------------------------------------------------------------------
package Node::Identifier;
use base 'Node::Element';

sub _kind {
    return 'IDENTIFIER';
}

sub to_string {
    my ($self, $as_scalar) = @_;
    my $str = '$'.$self->value;
    given ($self->type->kind) {
        when ('HASH')   { $str = '%'.$self->value }
        when ('ARRAY')  { $str = '@'.$self->value }
        default         { $str = '$'.$self->value }
    } 
    if ($as_scalar) {
        given ($self->type->kind) {
            when ('HASH')   { $str = "\\$str" }
            when ('ARRAY')  { $str = "\\$str" }
        }        
    }
    return $str;
}

sub infer_type {
    my ($self, $type_manager) = @_;
    $self->type($type_manager->get($self->value));
    return $self->type;
}

sub imply_type {
    my ($self, $type_manager, $type) = @_;
    $self->type($type);
    $type_manager->set($self->value, $type);
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

sub infer_type {
    my ($self, $type_manager) = @_;
    # ARGV's type is an array of string types
    $self->type(new Type([new Type('STRING')]));
    return $self->type;
}

sub imply_type {
}

#-----------------------------------------------------------------------
package Node::Call;
use Constants;
use base 'Node::Element';

sub _kind {
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

sub _kind {
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
package Node::In;
use base 'Node::Element';

sub _kind {
    return 'IN';
}

#-----------------------------------------------------------------------
package Node::Not;
use base 'Node::Element';

sub _kind {
    return 'NOT';
}

#-----------------------------------------------------------------------
package Node::And;
use base 'Node::Element';

sub _kind {
    return 'AND';
}

#-----------------------------------------------------------------------
package Node::Or;
use base 'Node::Element';

sub _kind {
    return 'OR';
}

#-----------------------------------------------------------------------
package Node::Number;
use base 'Node::Element';

sub _kind {
    return 'NUMBER';
}

#-----------------------------------------------------------------------
package Node::String;
use base 'Node';

sub _kind {
    return 'STRING';
}

sub to_string {
    my ($self) = @_;
    my $value = $self->value;
    return qq("$value")
}

sub infer_type {
    my ($self, $type_manager) = @_;
    $self->type(new Type('STRING'));
    return $self->type;
}

#-----------------------------------------------------------------------
package Node::Sprintf;
use Constants;
use base 'Node::Element';
Node::Sprintf->mk_accessors(qw(fmt));

sub _init {
    my ($self) = @_;
    $self->complete(FALSE);
    $self->fmt(undef);
}

sub _on_event_add_child {
    my ($self, $node) = @_;
    if ($self->fmt) {
        $self->children->append($node);
        $self->_peel_multilist;
        $self->_interpolate_args if ($self->fmt->kind eq 'STRING');
        $self->complete(TRUE);
    } else {
        $self->fmt($node);
    }
    return FALSE;
}

sub to_string {
    my ($self) = @_;
    my $str;
    if ($self->kind eq 'STRING'){
        $str = '"' . $self->value . '"';
    } else {
        my $fmt_str = $self->fmt->to_string;
        my $args = $self->join_children;
        $str = "sprintf($fmt_str, $args)";
    }
    return $str;
}

# returns true if successfully appended str
sub append_to_fmt {
    my ($self, $str) = @_;
    my $appended = FALSE;
    if ($self->fmt->kind eq 'STRING') {
        $self->fmt->{value} .= $str;
        $appended = TRUE;
    }
    return $appended;
}

sub infer_type {
    my ($self, $type_manager) = @_;
    $self->type(new Type('STRING'));
    return $self->type;
}

sub _kind {
    return 'SPRINTF';
}

# where possible interpolate arguments
# if all arguments interpolated then convert to string node
sub _interpolate_args {
    my ($self) = @_;

    # break up fmt into %.* parts
    my @parts = split(/(%\s*.)/, $self->fmt->value);

    my $new_fmtstr;
    my @old_args = $self->children->get_lists;
    my $new_args = new MultiList;
    my $interpolatable = ['NUMBER', 'STRING', 
                          'SUBSCRIPT', 'IDENTIFIER'];

    for my $part (@parts) {
        my ($arg, $kind);
        if ($part ~~ /%$/ or $part !~ /^%/) {
            # non-fmt parts
            $new_fmtstr .= $part;
            next;
        }
        if (($arg = shift @old_args) &&             # defined arg
            (@$arg == 1) &&                         # single node
            ($kind = $arg->[0]->kind) &&            # get node kind
            ($kind ~~ $interpolatable) &&           # correct type
            ($part ~~ /^%[sd]/)) {                  # simple fmt
            $new_fmtstr .= $arg->[0]->to_string;
        } else {
            if ($arg) {
                $new_args->new_list unless $new_args->is_empty;
                $new_args->append(@$arg);
            }
            $new_fmtstr .= $part;
        } 
    }

    if ($new_args->is_empty) {
        # we can transform this node into a regular string ^_^
        $self->value($new_fmtstr);
        $self->kind('STRING');
    } else {
        # we still have arguments, so still a sprintf -_-'
        $self->children($new_args);
        $self->fmt(new Node::String($new_fmtstr));
    }
}

#-----------------------------------------------------------------------
package Node::Seperator;
use base 'Node::Element';

sub _kind {
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
package Node::Indent;
use base 'Node';

sub _kind {
    return 'INDENT';
}

#-----------------------------------------------------------------------
package Node::Whitespace;
use base 'Node';

sub _kind {
    return 'WHITESPACE';
}

#-----------------------------------------------------------------------
package Node::Lncontinue;
use base 'Node';

sub _kind {
    return 'LNCONTINUE';
}

#-----------------------------------------------------------------------
package Node::Comment;
use base 'Node';

sub _kind {
    return 'COMMENT';
}

#-----------------------------------------------------------------------
# Indicates an unrecognised token
package Node::Error;
use base 'Node';

sub _kind {
    return 'ERROR';
}

1;