#
#  Parser.pm
#  Defines a Parser class, for the creation of a abstract syntax tree 
#  like structure from a sequence of node tokens.
#
#  Created by Alen Bou-Haidar on 19/09/14, edited 25/9/14
#

package Parser;

use strict;
use warnings;
use Stack;
use Node;
use constant TRUE   => 1;
use constant FALSE  => 0;

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
    my $node;                       # current node
    my $peak;                       # next node
    my $top;                        # current incomplete node
    my $incomp_stk = new Stack::;   # stack of incomplete nodes
    my $indent_stk = new Stack::;   # stack tracking changes in indent


    # adds node as child to top of incomp_stk
    my $add_node = sub {
        if ($top->is_compound and not $node->is_statement) {
            # compound statments only accept other statments so in this
            # case we need to push an expression statement first
            $top = new Node::Expression;
            $incomp_stk->push($top);
        } elsif ( $top->kind eq 'EXPRESSION' and 
                 $node->kind eq 'COLN_SEPERATOR' and 
                 $peak->kind ne 'STMT_SEPERATOR') {
            # we are at the end of a conditional for a composite stmt
            # and stmt is a one liner so push new indent level 
            $indent_stk->push($indent_stk->top + 4);
        }
        $top->add_child($node);
        if ($top->complete) {
            $incomp_stk->pop;
            $incomp_stk->top->add_child($top);
        }
    }

    # updates indent and completes compound stmts when required
    my $check_indent = sub {
        my $curr = $node->value;
        $indent_stk->push($curr) if ($curr > $indent_stk->top);
        while ($curr < $indent_stk->top) {
            $indent_stk->pop;
            $top = $incomp_stk->pop;
            $incomp_stk->top->add_child($top);
        }
    } 

    # Node::Code is the root node of the tree
    $incomp->push(new Node::Code);

    while ($lexer->has_next) { 
        $node = $lexer->next;
        $peak = $lexer->peak;
        $top  = $incomp_stk->top;
        
        if ($peak and $peak->kind eq 'METHOD_CALL') {
            $node = $incomp_stk->pop if ($node->kind eq 'CLOSER');
            $peak->add_caller($node);
        } elsif ($node->kind eq 'INDENT') {
            $check_indent->();
        } elsif ($node->complete) {
            $add_child->();
        } else {
            $incomp_stk->push($node);
        }
    }

    return $incomp->pop;
}


