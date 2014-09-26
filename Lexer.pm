#
#  Lexer.pm
#  Lexer is a class that takes in a list of python code and performs 
#  lexical analysis, breaking it up into node tokens. 
#
#  Created by Alen Bou-Haidar on 19/09/14, edited 26/9/14
#

package Lexer;

use strict;
use warnings;
use Node;
use feature 'switch';
use constant KW_ERROR  => qw(del is raise assert from lambda global 
                             try class except yield exec finally pass);

# matches the exsistance of indent on a line
my $re_indent      = qr/(^\s*)[^#\s]/;

# matches a floating point number
my $re_float       = qr/^[+-]?(?=\d+\.|\.\d+)\d*\.\d*(e[-+]?\d+)?/i;

# matches a hexadecimal number
my $re_hex         = qr/^[+-]?0x[a-f0-9]+/i;

# matches a octal number
my $re_octal       = qr/^[+-]?0[0-7]*/;

# matches a decimal number
my $re_decimal     = qr/^[+-]?[1-9][0-9]*/;

# matches assigment operators
# =   +=    -=    *=    /=    %=    &=    |=    ^=    >>=   <<=   **= 
my $re_assignment  = qr/^(<<|>>|\*\*|\/|[-+*%&|^])?=/;

# matches arithmetic operators
# +   -   *   /   **   %
my $re_arithmetic  = qr/^(\+|-|\*\*|\*|\/|%)/;

# matches bitwise operators
# <<    >>    &   |   ^   ~
my $re_bitwise     = qr/^(<<|>>|&|\||\^|~)/;

# matches comparison operators
# <   >     <=    >=    ==    !=    <>
my $re_comparison  = qr/^(<=|>=|==|!=|<>|<|>)/;

# matches regular and raw strings; does not match unicode and multiline
my $re_string      = qr/^(r?)("|')(?!\2\2)(.*?)(?<!\\)\2/i;

# matches enclosing brackets
my $re_encloser    = qr/^[][(){}]/;

# matches seperator elements
my $re_seperator   = qr/^[,:;]/;

# matches a comment
my $re_comment     = qr/^\s*#.*/;

# matches any whitespace characters
my $re_whitespace  = qr/^\s*/;

# matches any identifier; does not match a call 
my $re_identifier  = qr/^[a-z_]\w*\s*(\.\s*(?!\w+\s*\()[a-z_]\w*\s*)*/i;

# matches method and function calls
my $re_call        = qr/^\.\s*[a-z_]\w*\s*\(/i;


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

# returns next token, and removes from list
sub next {
    my $self = shift;
    return shift @{$self->{nodes}}; 
}

# returns next token
sub peak {
    my $self = shift;
    return @{$self->{nodes}}[0]; 
}

# converts a list of lines into node tokens
sub tokenize {
    my ($self, @lines)  = @_;
    my @nodes = ();

    for my $line (@lines) {
        chomp $line;                # remove new lines
        my $str = $line;            # str will be consumed
        my @token_buffer = ();      # hold nodes incase of error
        my $node;
        my $comment;

        # scan at start for indent
        if ($str =~ /$re_indent/) {
            $node = $self->_get_indent($str);
            push @token_buffer, $node;
        }

        # consume $str and create node tokens.
        while($str) {
            $node = $self->_extract_node(\$str);
                
            if ($node->kind eq 'WHITESPACE') {
                # ignore any whitespace
                next;
            } elsif ($node->kind eq 'COMMENT') {
                # hold the comment
                $comment = $node;
                last;
            } elsif ($node->kind eq 'ERROR') {
                # return entire line as a comment
                @token_buffer = (new Node::Comment("#$line"));
                last;
            } else {
                push @token_buffer, $node;
            }   
        }

        # remove trailing stmt seperator
        if ($self->_trailing_stmt_seperator(@token_buffer)) {
            pop @token_buffer;
        }

        # add comment in corrent spot, so it can be added to a stmt
        if (defined $comment) {
            if (@token_buffer > 0 and $token_buffer[0]->is_statement) {
                splice @token_buffer, 1, 0, $comment;
            } else {
                unshift @token_buffer, $comment;
            }
        }

        # add final stmt sepeartor
        push @token_buffer, new Node::Seperator(';');
        
        # push buffer onto nodes list
        push @nodes, @token_buffer;
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
        
        when (/$re_seperator/)  { $node = new Node::Seperator($&);
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
        
        when (/$re_identifier/) { $node = $self->_get_identifier($&);
                                  $$str =~ s/$re_identifier// }

        when (/$re_call/)       { $node = $self->_get_call($&);
                                  $$str =~ s/$re_call// }

        when (/$re_comment/)    { $node = new Node::Comment($$str);
                                  $$str =~ s/$re_comment// }

        when (/$re_whitespace/) { $node = new Node::Whitespace();
                                  $$str =~ s/$re_whitespace// }

        default                 { $node = new Node::Error() }
    }

    return $node;
}

# Create correct node based on identifier
sub _get_identifier {
    my ($self, $word) = @_;
    my $node;
    $word =~ s/\s//g;
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
        when ('sys.stdout') { $node = new Node::Stdout }
        when ('sys.stdin')  { $node = new Node::Stdin }
        when ('sys.argv')   { $node = new Node::Argv }
        when ([KW_ERROR])   { $node = new Node::Error }
        default             { $node = new Node::Identifier($word) }
    }

    return $node;
}

# Create correct node based on call
sub _get_call {
    my ($self, $call) = @_;
    my $node;
    $call =~ s/[\s\(]//g;
    given ($call) {
        when ('int')        { $node = new Node::CallInt }
        when ('len')        { $node = new Node::CallLen }
        when ('open')       { $node = new Node::CallOpen }
        when ('sorted')     { $node = new Node::CallSorted }
        when ('range')      { $node = new Node::CallRange }
        when ('.write')     { $node = new Node::CallWrite }
        when ('.readline')  { $node = new Node::CallReadline }
        when ('.readlines') { $node = new Node::CallReadlines }
        when ('.input')     { $node = new Node::CallFileinput }
        when ('.append')    { $node = new Node::CallAppend }
        when ('.pop')       { $node = new Node::CallPop }
        when ('.keys')      { $node = new Node::CallKeys }
        when ('.split')     { $node = new Node::CallSplit }
        when ('.join')      { $node = new Node::CallJoin }
        when ('.match')     { $node = new Node::CallMatch }
        when ('.search')    { $node = new Node::CallSearch }
        when ('.sub')       { $node = new Node::CallSub }
        default             { $node = new Node::Call($call) }
    }

    return $node;
}

# extract unix compatible expansion of tabs
# TAB 1-8 spaces to get multiple of 8 upto and including TAB
sub _get_indent {
    my ($self, $str) = @_;
    my $node;
    my $whitespace = $1;
    my $num_spaces = 0;
    while ($whitespace =~/( +|\t)/g) {
          if ($1 eq "\t") {
                $num_spaces += 8 - ($num_spaces % 8);
          } else {
                $num_spaces += length($1);
          }
    }
    $node = new Node::Indent($num_spaces);
    
    return $node;
}

# return True when a list has a training stmt_seperator
sub _trailing_stmt_seperator {
    return (@_ > 1 and $_[-1]->kind eq 'STMT_SEPERATOR');
}

1;