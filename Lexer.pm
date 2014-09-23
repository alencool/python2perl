#
#  Lexer.pm
#  Lexer is a class that takes in a list of python code and performs 
#  lexical analysis, breaking it up into node tokens. 
#
#  Created by Alen Bou-Haidar on 19/09/14, edited 24/9/14
#

package Lexer;

use strict;
use warnings;
use Node;
use feature 'switch';
use constant KW_ERROR  => qw(del is raise assert from lambda global 
                             try class except yield exec finally pass);

# matches the exsistance of indent on a line
my $re_indent       = qr/(^\s*)[^#]/;

# matches a floating point number
my $re_float        = qr/^[+-]?[0-9]*[.][0-9]*(e[-+]?[0-9]+)?/i;

# matches a hexadecimal number
my $re_hex          = qr/^[+-]?0x[a-f0-9]+/i;

# matches a octal number
my $re_octal        = qr/^[+-]?0[0-7]*/;

# matches a decimal number
my $re_decimal      = qr/^[+-]?[1-9][0-9]*/;

# matches assigment operators
# =   +=    -=    *=    /=    %=    &=    |=    ^=    >>=   <<=   **= 
my $re_assignment   = qr/^(<<|>>|\*\*|\/|[-+*%&|^])?=/;

# matches arithmetic operators
# +   -   *   /   **   %
my $re_arithmetic   = qr/^(\+|-|\*\*|\*|\/|%)/;

# matches bitwise operators
# <<    >>    &   |   ^   ~
my $re_bitwise      = qr/^(<<|>>|&|\||\^|~)/;

# matches comparison operators
# <   >     <=    >=    ==    !=    <>
my $re_comparison   = qr/^(<=|>=|==|!=|<>|<|>)/;

# matches regular and raw strings; does not match unicode and multiline
my $re_string       = qr/^(r?)("|')(?!\2\2)(.*?)(?<!\\)\2/i;

# matches enclosing brackets
my $re_encloser     = qr/^[][(){}]/;

# matches seperator elements
my $re_seperator    = qr/^[.,:;]/;

# matches a comment
my $re_comment      = qr/\s*#/;

# matches any whitespace characters
my $re_whitespace   = qr/^\s*/;

# matches any words
my $re_word         = qr/^[a-z_][a-z0-9_]*/i;


# constructor
sub new {
    my ($class, @args) = @_;
    my $self = { nodes => [] };
    my $object = bless $self, $class;
    return $object;
}

# returns true if more nodes
sub has_next {
    my $self = shift;
    return @{$self->{nodes}} > 0;
}

# returns next token
sub next {
    my $self = shift;
    return shift @{$self->{nodes}}; 
}

# converts a list of lines into node tokens
sub tokenize {
    my ($self, @lines)  = @_;
    my @nodes = ();

    for my $line (@lines) {
        chomp $line;
        my $str = $line;            # str will be consumed
        my @token_buffer = ();      # hold nodes incase of error
        my $comment = '';           # holds the comment if one exists
        my $node;

        # scan at start for indent
        if ($str =~ /$re_indent/) {
            $node = $self->_get_indent($str);
            push @token_buffer, $node;
        }

        # consume $str and create node nodes.
        while($str) {

            $node = $self->_extract_node(\$str);

            if ($node->kind eq 'ERROR') {
                # return entire line as a comment
                $comment = "#$line";
                @token_buffer = ();
                last;
            } elsif ($node->kind eq 'WHITESPACE') {
                # ignore whitespace
                next;
            } elsif ($node->kind eq 'COMMENT') {
                $comment = $node->value;
                last;
            } else {
                push @token_buffer, $node;
            }   
        }

        # push entire line and buffer onto nodes list
        push @nodes, new Node::Start($line);
        push @nodes, @token_buffer;
        push @nodes, new Node::End($comment);
    }

    $self->{nodes} = \@nodes;
}

# Extracts a token node from $str reference
sub _extract_node {
    my ($self, $str) = @_;
    my ($node, $value);


    given ($$str) {
        when (/$re_encloser/)   { $node = new Node::Encloser($&);
                                  $$str =~ s/$re_encloser// }
        
        when (/$re_float/)      { $node = new Node::Number($&);
                                  $$str =~ s/$re_float// }
        
        when (/$re_hex/)        { $node = new Node::Number($&);
                                  $$str =~ s/$re_hex// }
        
        when (/$re_octal/)      { $node = new Node::Number($&);
                                  $$str =~ s/$re_octal// }
        
        when (/$re_decimal/)    { $node = new Node::Number($&);
                                  $$str =~ s/$re_decimal// }
        
        when (/$re_seperator/)  { $node = new Node::Number($&);
                                  $$str =~ s/$re_seperator// }
        
        when (/$re_assignment/) { $node = new Node::Assignment($&);
                                  $$str =~ s/$re_assignment// }
        
        when (/$re_arithmetic/) { $node = new Node::Arithmetic($&);
                                  $$str =~ s/$re_arithmetic// }
        
        when (/$re_bitwise/)    { $node = new Node::Bitwise($&);
                                  $$str =~ s/$re_bitwise// }
        
        when (/$re_comparison/) { $node = new Node::Comparison($&);
                                  $$str =~ s/$re_comparison// }
        
        when (/$re_string/)     { $value = $3;
                                  if (lc($1) eq 'r') {
                                       # raw string
                                       $value = qq('$value');
                                  } else {
                                       #escape $ symbols
                                       $value =~ s/\$/\\\$/g;
                                       #escape @ symbols
                                       $value =~ s/@/\\@/g;   
                                       $value = qq("$value");
                                  }
                                  $node = new Node::String($value);
                                  $$str =~ s/$re_string// }
        
        when (/$re_word/)       { $node = $self->_get_word_node($&);
                                  $$str =~ s/$re_word// }

        when (/$re_comment/)    { $node = new Node::Comment($$str) }

        when (/$re_whitespace/) { $node = new Node::Whitespace();
                                  $$str =~ s/$re_whitespace// }

        default                 { $node = new Node::Error() }
    }

    return $node;
}

# Create correct node based on word
sub _get_word_node {
    my ($self, $word) = @_;
    my $node;
    given ($word) {
        when ('if')         { $node = new Node::If }
        when ('elif')       { $node = new Node::Elif }
        when ('else')       { $node = new Node::Else }
        when ('for')        { $node = new Node::For }
        when ('while')      { $node = new Node::While }
        when ('def')        { $node = new Node::Def }
        when ('return')     { $node = new Node::Return }
        when ('break')      { $node = new Node::Break }
        when ('continue')   { $node = new Node::Continue }
        when ('print')      { $node = new Node::Print }
        when ('not')        { $node = new Node::Logical('not') }
        when ('and')        { $node = new Node::Logical('and') }
        when ('or')         { $node = new Node::Logical('or') }
        when ('True')       { $node = new Node::Number('1') }
        when ('False')      { $node = new Node::Number('0') }
        when ('in')         { $node = new Node::In }
        when ('import')     { $node = new Node::Invisible }
        when ([KW_ERROR])   { $node = new Node::Error }
        default             { $node = new Node::Identifier($word) }
    }

    return $node;
}

# extract unix compatible expansion of tabs
sub _get_indent {
    my ($self, $str) = @_;
    my $node;
    # line has statements, find indent 
    # TAB 1-8 spaces to get multiple of 8 upto and including TAB

    my $whitespace = $1;
    my $num_spaces = 0;
    while ($whitespace =~/( +|\t)/g) {
          if ($1 eq "\t") {
                $num_spaces += 8 - ($num_spaces % 8);
          } else {
                $num_spaces += length($1);
          }
    }

    #remove front indent
    $node = new Node::Indent($num_spaces);
    
    return $node;
}

1;