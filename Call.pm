#
#  Call.pm
#  Defines is a set of classes that represent function and method calls 
#  in python for use in the creation of a tree.
#
#  Created by Alen Bou-Haidar on 6/10/14, edited 6/10/14
#

use strict;
use warnings;
use feature 'switch';
use Type;
use Element;
#-----------------------------------------------------------------------
#   ___      _ _   _  _         _        
#  / __|__ _| | | | \| |___  __| |___ ___
# | (__/ _` | | | | .` / _ \/ _` / -_|_-<
#  \___\__,_|_|_| |_|\_\___/\__,_\___/__/
#                                        
#-----------------------------------------------------------------------

package Node::Call;
use Constants;
use base 'Node::Element';

sub _init {
    my ($self) = @_;
    $self->complete(FALSE);
}

sub _kind {
    return 'FUNCTION_CALL';
}

sub infer_type {
    my ($self, $type_manager) = @_;
    my $type = $self->SUPER::infer_type($type_manager);
    if ($self->subkind eq 'CALL') {
        print $self->value;
        my @param_types;
        if ($type->kind ~~ ['NUMBER', 'STRING', 'HASH']) {
            push @param_types, $type;
        } else {
            @param_types = @{$type->data};
        }
        $type = $type_manager->request_func($self->value, @param_types);
    } else {
        $type = new Type('NUMBER');
    }
    $self->type($type);
    return $self->type;
}

sub _on_event_add_child {
    my ($self, $node) = @_;
    my $add_child = FALSE;

    if ($node->kind eq 'COMA_SEPERATOR') {
        $self->children->new_list; 
    } elsif ($node->kind eq 'CLOSER') {
        $self->complete(TRUE);
    } else {
        $add_child = TRUE;
    }

    return $add_child;
}

sub _convert_pattern {
    my ($self, $patt) = @_;
    $patt =~ s/\\\\/\\/g;
    return $patt;
}

sub to_string {
    my ($self) = @_;
    my $args = $self->join_children;
    my $name = $self->value;
    return qq/$name($args)/;
}

#-----------------------------------------------------------------------
package Node::CallInt;
use base 'Node::Call';

sub to_string {
    my ($self) = @_;
    my $args = $self->join_children;

    return qq/int($args)/;
}

#-----------------------------------------------------------------------
package Node::CallLen;
use base 'Node::Call';

sub to_string {
    my ($self) = @_;
    $self->_peel_multilist;
    my $node = $self->children->get_single;
    my $str = $node->to_string('EXPAND');
    my $type_kind = $node->type->kind;
    my $kind = $node->kind;
    if ($type_kind eq 'STRING') {
        $str = qq/length($str)/;
    } elsif ($kind eq 'IDENTIFIER') {
        $str = qq/scalar($str)/;
    } elsif ($kind eq 'SUBSCRIPT') {
        $str = qq/scalar($str)/;
    } elsif ($kind eq 'LIST') {
        $str = $node->to_string;
        $str = qq/scalar(\@{$str})/;
    } else {
        $str = qq/scalar(\@{[$str]})/;
    }
    return $str;
}


#-----------------------------------------------------------------------
package Node::CallOpen;
use base 'Node::Call';

sub to_string {
    my ($self, $handle) = @_;    
    my $file = $self->children->get_list(0)->[0];
    my $mode = $self->children->get_list(1);
    
    # assign default handle F if none provided
    if ($handle and $handle eq 'EXPAND') {
        $handle = 'F';
    } else {
        $handle = ($handle ? uc($handle->value) : 'F');
    }

    # convert mode
    $mode = ($mode ? $mode->[0]->value : qq/"<"/ );
    given ($mode) {
        when ('r')  { $mode = qq/"<"/   }
        when ('r+') { $mode = qq/"+<"/  }
        when ('w')  { $mode = qq/">"/   }
        when ('w+') { $mode = qq/"+>"/  }
        when ('a')  { $mode = qq/">>"/  }
        when ('a+') { $mode = qq/"+>>"/ }
    }

    # get filename
    my $file_str = $file->to_string;
    my $file_val = ($file->kind eq 'STRING' ? $file->value : $file_str);

    my $str = qq/open($handle, $mode, $file_str) or die /;
    $str .= qq/"\$0: can not open $file_val: \$!"/;
    return $str;
}


#-----------------------------------------------------------------------
package Node::CallSorted;
use base 'Node::Call';

sub to_string {
    my ($self) = @_;
    my $node = $self->children->get_single;
    my $str = $node->to_string('EXPAND');
    my $is_num = ($self->type->get_query(0)->kind eq 'NUMBER');

    if ($node->type->kind eq 'HASH') {
        $str = "sort(keys($str))";
    } elsif ($is_num) {
        $str = "sort({\$a <=> \$b} $str)";
    } else {
        $str = "sort($str)";
    }

    return $str;
}

sub infer_type {
    my ($self, $type_manager) = @_;
    $self->SUPER::infer_type($type_manager);
    my $node = $self->children->get_single;
    if ($node->type->kind eq 'ARRAY') {
        $self->type($node->type);
    } else {
        $self->type(new Type([new Type('STRING')]));
    }
    return $self->type;
}


#-----------------------------------------------------------------------
package Node::CallRange;
use base 'Node::Call';

# range(i)      => 0 .. i-1
# range(i, j)   => i .. j-1
sub to_string {
    my ($self) = @_;
    my $str;
    my $i = $self->children->get_list(0);
    my $j = $self->children->get_list(1);

    if ($j and @$j > 0) {
        # consider 2 argument range
        $j = $self->_nodes_minus_one($j);
        $str = $self->join_nodes($i).'..'.$self->join_nodes($j);
    } else {
        # consider 1 argument range
        $i = $self->_nodes_minus_one($i);
        $str = '0..'.$self->join_nodes($i);
    }

    return $str;
}

sub infer_type {
    my ($self, $type_manager) = @_;
    $self->SUPER::infer_type($type_manager);
    $self->type(new Type([1..10]));
    return $self->type;
}

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

sub infer_type {
    my ($self, $type_manager) = @_;
    $self->SUPER::infer_type($type_manager);
    $self->caller->infer_type($type_manager);
    return $self->type;
}

#-----------------------------------------------------------------------
package Node::CallClose;
use base 'Node::MethodCall';

# caller is fileobj
# exactly one argument string type
sub to_string {
    my ($self) = @_;
    my $cl_value = uc($self->caller->value);
    return "close($cl_value)";
}

#-----------------------------------------------------------------------
package Node::CallWrite;
use base 'Node::MethodCall';

# caller is fileobj
# exactly one argument string type
sub to_string {
    my ($self) = @_;
    my $str;
    my $cl_value = uc($self->caller->value);
    my $cl_subkind = $self->caller->subkind;
    my $arg = $self->children->get_single->to_string;
    given ($cl_subkind) {
        when ('IDENTIFIER') { $str = "print($cl_value, $arg)" }
        when ('STDERR')     { $str = "print($cl_subkind, $arg)" }
        default             { $str = "print($arg)" }
    }
    return $str;
}

#-----------------------------------------------------------------------
package Node::CallReadline;
use base 'Node::MethodCall';

sub to_string {
    my ($self) = @_;
    my $str;
    my $cl_value = uc($self->caller->value);
    my $cl_subkind = $self->caller->subkind;
    given ($cl_subkind) {
        when ('IDENTIFIER') { $str = "<$cl_value>" }
        default             { $str = "<STDIN>" }
    }
    return $str;
}

# returns a type STRING
sub infer_type {
    my ($self, $type_manager) = @_;
    $self->SUPER::infer_type($type_manager);
    $self->caller->infer_type($type_manager);
    $self->type(new Type('STRING'));
    return $self->type;
}

#-----------------------------------------------------------------------
package Node::CallReadlines;
use base 'Node::CallReadline';

# returns a type ARRAY of STRING's
sub infer_type {
    my ($self, $type_manager) = @_;
    $self->SUPER::infer_type($type_manager);
    $self->type(new Type([new Type('STRING')]));
    return $self->type;
}

#-----------------------------------------------------------------------
package Node::CallFileinput;
use base 'Node::MethodCall';

#-----------------------------------------------------------------------
package Node::CallAppend;
use base 'Node::MethodCall';

sub to_string {
    my ($self) = @_;
    my $lst_org = $self->caller->to_string('EXPAND');
    my $item = $self->children->get_single->to_string;
    return "push($lst_org, $item)";
}

sub infer_type {
    my ($self, $type_manager) = @_;
    $self->SUPER::infer_type($type_manager);
    my $item = $self->children->get_single;
    if ($self->caller->type->kind eq 'ARRAY') {
        # if caller list is empty and appending an item can 
        # potentially modify its original type
        $self->caller->type->set_query(0, $item->type);
    }
}

#-----------------------------------------------------------------------
package Node::CallPop;
use base 'Node::MethodCall';

sub to_string {
    my ($self) = @_;
    my $str = $self->caller->to_string('EXPAND');

    if (not $self->is_leaf){
        $str = "pop($str)";
    } else {
        my $key = $self->_get_key;
        $str = "splice($str, $key, 1)";
    }
    return $str;
}

sub infer_type {
    my ($self, $type_manager) = @_;
    $self->SUPER::infer_type($type_manager);
    my $type = $self->caller->type->get_query($self->_get_key);
    $self->type($type);
    return $self->type;
}

sub _get_key {
    my ($self) = @_;
    my $key = -1;
    if (not $self->is_leaf){
        $key = $self->children->get_single;
        $key = ($key->kind eq 'NUMBER' ? $key->value : -1);
    }
    return $key;
}

#-----------------------------------------------------------------------
package Node::CallKeys;
use base 'Node::MethodCall';

sub to_string {
    my ($self) = @_;
    my $str = $self->caller->to_string('TARGET');
    given ($self->caller->kind) {
        when ('IDENTIFIER') { $str = "keys($str)" }
        default             { $str = "keys(\%{$str})" }
    }
    return $str;
}

# returns a type ARRAY of STRING's
sub infer_type {
    my ($self, $type_manager) = @_;
    $self->SUPER::infer_type($type_manager);
    $self->type(new Type([new Type('STRING')]));
    return $self->type;
}

#-----------------------------------------------------------------------
package Node::CallSplit;
use base 'Node::MethodCall';

# STRING.split(DELIMITER [, MAX]) => split(DELIMITER, STRING [, MAX+1])
# DELIMITER default ' '
sub to_string {
    my ($self) = @_;
    my $str;
    my $string_arg = $self->caller->to_string;
    my $deli = $self->children->get_list(0);
    my $max = $self->children->get_list(1);
    $deli = (@$deli ? $deli->[0]->value : ' ');
    $max = ($max ? $self->join_nodes($self->_nodes_plus_one($max)) : undef);

    if (defined $max) {
         $str = "split(/\\Q$deli\\E/, $string_arg, $max)";
    } else {
         $str = "split(/\\Q$deli\\E/, $string_arg)";
    }

    return $str;
}

# returns a type ARRAY of STRING's
sub infer_type {
    my ($self, $type_manager) = @_;
    $self->SUPER::infer_type($type_manager);
    $self->type(new Type([new Type('STRING')]));
    return $self->type;
}

 
 

#-----------------------------------------------------------------------
package Node::CallJoin;
use base 'Node::MethodCall';

# DELIMITER.join(ARRAY) => join(STRING, ARRAY)
sub to_string {
    my ($self) = @_;
    my $deli = $self->caller->to_string;
    my $arg = $self->children->get_single->to_string('EXPAND');
    return "join($deli, $arg)";
}


# returns a type STRING
sub infer_type {
    my ($self, $type_manager) = @_;
    $self->SUPER::infer_type($type_manager);
    $self->type(new Type('STRING'));
    return $self->type;
}

#-----------------------------------------------------------------------
package Node::CallSearch;
use base 'Node::MethodCall';

# match zero or more characters anywhere inside the string
sub to_string {
    my ($self, $handle) = @_;
    my $str = '';
    if ($handle ne 'EXPAND') {
        my $patt = $self->children->get_list(0)->[0]->value;
        my $text = $self->children->get_list(1)->[0]->to_string;
        $patt = $self->_convert_pattern($patt);
        $handle = $handle->to_string;
        $str = "$handle = ($text =~ /$patt/)";
    }
    return $str;
}

#-----------------------------------------------------------------------
package Node::CallMatch;
use base 'Node::CallSearch';

# match zero or more characters at the beginning of string
sub to_string {
    my ($self, $handle) = @_;
    my $str = '';
    if ($handle ne 'EXPAND') {
        $str = $self->SUPER::to_string($handle);
        # make sure it only matches at the start
        $str =~ s/=~ \//=~ \/^/ if $str !~ /=~ \/^/;
    }
    return $str;
}

#-----------------------------------------------------------------------
package Node::CallSub;
use base 'Node::MethodCall';

sub to_string {
    my ($self, $handle) = @_;
    my $str = '';
    if ($handle ne 'EXPAND') {
        my $patt = $self->children->get_list(0)->[0]->value;
        my $repl = $self->children->get_list(1)->[0]->value;
        my $text = $self->children->get_list(2)->[0]->to_string;
        $patt = $self->_convert_pattern($patt);
        $handle = $handle->to_string;
        $str = "($handle = $text) =~ s/$patt/$repl/g";
    }
    return $str;
}

#-----------------------------------------------------------------------
package Node::CallGroup;
use base 'Node::MethodCall';

sub to_string {
    my ($self) = @_;
    my $num = $self->children->get_single->value;
    return "\$$num";
}

sub infer_type {
    my ($self) = @_;
    $self->type(new Type('STRING'));
    return $self->type;
}

1;