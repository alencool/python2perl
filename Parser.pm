#
#  Parser.pm
#  Defines a Parser class, for the creation of a abstract syntax tree 
#  like structure from a sequence of node tokens.
#
#  Created by Alen Bou-Haidar on 19/09/14, edited 24/9/14
#

package Parser;

use strict;
use warnings;
use Stack;
use Node;


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
    my $token;
    my $line;
    my $indent;
    my $compound;

    my $incomp = new Stack;     # stack of incomplete nodes
    my $indent = new Stack;     # stack tracking changes in indent

    $incomp->push(new Node::Code);

    while ($lexer->has_next) { 

        $node = $lexer->next;

        if ($node->kind eq 'START') {

        } elsif ($node->kind eq 'END') {

        } elsif ($node->kind eq 'INDENT') {
            my $curr_indent = $node->value;
            if ($curr_indent > $indent->top) {
                # Deeper indent level

                if (not $incomp->top->indent_expected) {
                    die "Unexpected indent encountered!";
                }
                # Update new indent level
                $indent->push($curr_indent);

            } elsif ($curr_indent < $indent->top) {
                # Shallow indent level 
                while ($curr_indent < $indent->top) {
                    $indent->pop;
                    if ($curr_indent > $indent->top) {
                        die "Error unmatched indent";
                    } else {
                        # Complete the current incomplete statement
                        # pop it off and add it to new top
                        $old_top_incomp = $incomp->pop;
                        $incomp->top->add_child($old_top_incomp);
                    }

                }
            } else {
                # Indent level unchanged              
            }

        } else {
            #if this node is not complete push it onto incomp stack
            #else add_child to 
        }   
    #completes while
    }
}

