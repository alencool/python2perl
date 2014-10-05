#
#  Parser.pm
#  Defines a Parser class, for the creation of a abstract syntax tree 
#  like structure from a sequence of node tokens.
#
#  Created by Alen Bou-Haidar on 19/09/14, edited 5/10/14
#

package Parser;

use strict;
use warnings;
use Stack;
use Element;
use Simple;
use Compound;
use Constants;

# constructor
sub new {
    my ($class, @args) = @_;
    my $self = {};
    my $object = bless $self, $class;
    return $object;
}

# returns an tree representation of the code
sub parse {
    my ($self, $lexer)  = @_;
    my $root;                       # root node of the tree
    my $node;                       # current node
    my $peak;                       # next node
    my $top;                        # current incomplete node
    my $incomp_stk = new Stack::;   # stack of incomplete nodes
    my $indent_stk = new Stack::;   # stack tracking changes in indent
    my ($add_node, $check_indent);

    # adds node as child to top of incomp_stk
    $add_node = sub {
        if ($top->is_compound and not $node->is_statement) {
            # compound statments only accept other statments so in this
            # case we need to push an expression statement first
            $top = new Node::Expression;
            $incomp_stk->push($top);
        }
        if ( $top->kind eq 'EXPRESSION' and
            $node->kind eq 'COLN_SEPERATOR' and 
            $peak->kind ne 'STMT_SEPERATOR') {
            # we are at the end of a conditional for a composite stmt
            # and stmt is a one liner so push new indent level 
            $indent_stk->push($indent_stk->top + 4);
        }
        $top->add_child($node);
        if ($top->complete) {
            $node = $incomp_stk->pop;
            $top = $incomp_stk->top;
            $add_node->();
        }
    };

    # updates indent and completes compound stmts when required
    $check_indent = sub {
        my $curr = $node->value;
        $indent_stk->push($curr) if ($curr > $indent_stk->top);
        while ($curr < $indent_stk->top) {
            $indent_stk->pop;
            $top = $incomp_stk->pop;
            $incomp_stk->top->add_child($top);
        }
    };

    # root is incomplete, so push it onto the incomp_stk
    $root = new Node::Code;
    $incomp_stk->push($root);

    # push indent level 0
    $indent_stk->push(0);

    while ($lexer->has_next) { 
        $node = $lexer->next;
        $peak = $lexer->peak;
        $top  = $incomp_stk->top;

        if ($peak and $peak->kind ~~ ['METHOD_CALL', 'SUBSCRIPT']) {
            $node = $incomp_stk->pop if ($node->kind eq 'CLOSER');
            $peak->set_caller($node);
        } elsif ($node->kind eq 'INDENT') {
            $check_indent->();
        } elsif ($node->complete) {
            $add_node->();
        } else {
            $incomp_stk->push($node);
        }
    }

    # Some final modifications to the tree
    $root->infer_type;
    $root->translate_sprintf;
    # $root->translate_list_add;
    $root->translate_notin;
    return $root;
}

1;