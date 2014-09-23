package Lexer;

use strict;
use warnings;
use Node;
use feature 'switch';
use constant KW_ERROR  => qw(del is raise assert from lambda global 
                             try class except yield exec finally pass);


# Compile Regex for each token type
my $reIndent        = qr/(^\s*)[^#]/;
my $reFloat         = qr/^[+-]?[0-9]*[.][0-9]*(e[-+]?[0-9]+)?/i;
my $reHex           = qr/^[+-]?0x[a-f0-9]+/i;
my $reOctal         = qr/^[+-]?0[0-7]*/;
my $reDecimal       = qr/^[+-]?[1-9][0-9]*/;
my $reAssignment    = qr/^(<<|>>|\*\*|\/|[-+*%&|^])?=/;
my $reArithmetic    = qr/^(\+|-|\*\*|\*|\/|%)/;
my $reBitwise       = qr/^(<<|>>|&|\||\^|~)/;
my $reComparison    = qr/^(<=|>=|==|!=|<>|<|>)/;
my $reString        = qr/^(r?)("|')(?!\2\2)(.*?)(?<!\\)\2/i;
my $reEncloser      = qr/^[][(){}]/;
my $reSeperator     = qr/^[.,:;]/;
my $reComment       = qr/\s*#/;
my $reWhitespace    = qr/^\s*/;
my $reWord          = qr/^[a-z_][a-z0-9_]*/i;

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
        if ($str =~ /$reIndent/) {
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
        when (/$reEncloser/)    { $node = new Node::Encloser($&);
                                  $$str =~ s/$reEncloser// }
        
        when (/$reFloat/)       { $node = new Node::Number($&);
                                  $$str =~ s/$reFloat// }
        
        when (/$reHex/)         { $node = new Node::Number($&);
                                  $$str =~ s/$reHex// }
        
        when (/$reOctal/)       { $node = new Node::Number($&);
                                  $$str =~ s/$reOctal// }
        
        when (/$reDecimal/)     { $node = new Node::Number($&);
                                  $$str =~ s/$reDecimal// }
        
        when (/$reSeperator/)   { $node = new Node::Number($&);
                                  $$str =~ s/$reSeperator// }
        
        when (/$reAssignment/)  { $node = new Node::Assignment($&);
                                  $$str =~ s/$reAssignment// }
        
        when (/$reArithmetic/)  { $node = new Node::Arithmetic($&);
                                  $$str =~ s/$reArithmetic// }
        
        when (/$reBitwise/)     { $node = new Node::Bitwise($&);
                                  $$str =~ s/$reBitwise// }
        
        when (/$reComparison/)  { $node = new Node::Comparison($&);
                                  $$str =~ s/$reComparison// }
        
        when (/$reString/)      { $value = $3;
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
                                  $$str =~ s/$reString// }
        
        when (/$reWord/)        { $node = $self->_get_word_node($&);
                                  $$str =~ s/$reWord// }

        when (/$reComment/)     { $node = new Node::Comment($$str) }

        when (/$reWhitespace/)  { $node = new Node::Whitespace();
                                  $$str =~ s/$reWhitespace// }

        default                 { $node = new Node::Error() }
    }

    return $node;
}

# Create correct node based on word
sub _get_word_node {
    my ($self, $word) = @_;
    my $node;
    given ($word) {
        when ('if')         { $node = new Node::If() }
        when ('elif')       { $node = new Node::Elif() }
        when ('else')       { $node = new Node::Else() }
        when ('for')        { $node = new Node::For() }
        when ('while')      { $node = new Node::While() }
        when ('def')        { $node = new Node::Def() }
        when ('return')     { $node = new Node::Return() }
        when ('break')      { $node = new Node::Break() }
        when ('continue')   { $node = new Node::Continue() }
        when ('print')      { $node = new Node::Print() }
        when ('not')        { $node = new Node::Logical('not') }
        when ('and')        { $node = new Node::Logical('and') }
        when ('or')         { $node = new Node::Logical('or') }
        when ('True')       { $node = new Node::Number('1') }
        when ('False')      { $node = new Node::Number('0') }
        when ('in')         { $node = new Node::In() }
        when ('import')     { $node = new Node::Invisible() }
        when ([KW_ERROR])   { $node = new Node::Error() }
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