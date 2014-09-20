package Lexer;

use strict;
use warnings;
use Words;

########################################################################
#                         Public Methods                               #
########################################################################

# constructor
sub new {
    my ($class, @args) = @_;
    my $self = { tokens => [] };
    my $object = bless $self, $class;
    return $object;
}

# returns true if more tokens
sub has_next {
    my $self = shift;
    return @{$self->{tokens}} > 0;
}

# returns next token
sub next {
    my $self = shift;
    return shift @{$self->{tokens}}; 
}

# converts a list of lines into tokens
sub tokenize {
    my ($self, @lines)  = @_;
    my @tokens = ();
    for my $line (@lines) {
        chomp $line;
        my $str = $line;            # str will be consumed
        my @token_buffer = ();      # hold tokens incase of error
        my $comment = '';           # holds the comment if one exists
        my $token;

        # scan at start for indent
        if ($str =~ m/(^\s*)[^#]/) {
            ($str, $token) = $self->_scan_indent($str);
            push @token_buffer, $token;
        }
        
        # scan for appropriate token based on 'peek' re
        # and consume the part of $str relating to the token.
        while($str) {
            if ($str =~ m/^[][(){}]/) {
                ($str, $token) = $self->_scan_encloser($str);

            } elsif ($str =~ m/^[+-]?[.]?[0-9]/) {
                ($str, $token) = $self->_scan_number($str);
            
            } elsif ($str =~ m/^[.,:;]/) {
                ($str, $token) = $self->_scan_seperator($str);

            } elsif ($str =~ m'^[-+*/%=&|^><~!]') {
                ($str, $token) = $self->_scan_symbol($str);
            
            } elsif ($str =~ m/^u?r?('|")/i) {
                ($str, $token) = $self->_scan_string($str);

            } elsif ($str =~ m/^[a-zA-Z_]/) {
                ($str, $token) = $self->_scan_word($str);
            
            } elsif ($str =~ m'^\s*#') {
                # rest of str is a comment
                $comment = $str;
                last;

            } elsif ($str =~ m'^\s+') {
                # ignore whitespace
                $str = substr $str, length($&);
                next;

            } else {
                $token = {type => 'error'};
            }
            
            if ($$token{type} eq 'error') {
                # return entire line as a comment
                $comment = "#$line";
                @token_buffer = ();
                last;
            } else {
                push @token_buffer, $token;
            }   
        }

        # push entire line and buffer onto tokens list
        push @tokens, {type => 'start', value => $line};
        push @tokens, @token_buffer;
        push @tokens, {type => 'end', value => $comment};
    }

    $self->{tokens} = \@tokens;
}


########################################################################
#                         Private Methods                              #
########################################################################


# scan for indent
sub _scan_indent {
    my ($self, $str) = @_;
    my $token;
    $str =~ m/(^\s*)[^#]/;
    # line has statements, find indent 
    # TAB 1-8 spaces to get multiple of 8 upto and including TAB
    my $whitespace = $1;
    my $indent = 0;
    while ($whitespace =~/( +|\t)/g) {
          if ($1 eq "\t") {
                $indent += 8 - ($indent % 8);
          } else {
                $indent += length($1);
          }
    }
    #remove front indent
    $str =~ s/^\s*//;
    $token = {type => 'indent', value => $indent};
    
    return ($str, $token);
}

sub _scan_number {
    my ($self, $str) = @_;
    my $token;
    
    if ($str =~ m/^[+-]?[0-9]*[.][0-9]*(e[-+]?[0-9]+)?/i || # float
        $str =~ m/^[+-]?0x[a-f0-9]+/i ||                    # hex
        $str =~ m/^[+-]?0[0-7]*/      ||                    # octal
        $str =~ m/^[+-]?[1-9][0-9]*/ ) {                    # decimal
        $str = substr $str, length($&);
        $token = {type => 'number', value => lc($&)};
    } else {
        $token = {type => 'error'};
    }

    return ($str, $token);
}

sub _scan_symbol {
    # assignment +=    -=      *=      /=     %=      =
    #            &=    |=      ^=      >>=    <<=     **=
    # arithmatic +     -       *       **     /       %
    # bitwise    <<    >>      &       |      ^       ~
    # comparison <     >       <=      >=     ==      !=    <>
    my ($self, $str) = @_;
    my $token;
    if ($str =~ m/^(<<|>>|\*\*|\/|[-+*%&|^])?=/) {
        $token = {type => 'assignment', value => $&};
    } elsif ($str =~ m/^(\+|-|\*\*|\*|\/|%)/) {
        $token = {type => 'arithmatic', value => $&};
    } elsif ($str =~ m/^(<<|>>|&|\||\^|~)/) {
        $token = {type => 'bitwise', value => $&};
    } elsif ($str =~ m/^(<=|>=|==|!=|<>|<|>)/) {
        $& =~ s/<>/!=/;
        $token = {type => 'comparison', value => $&};
    }
    $str = substr $str, length($&);

    return ($str, $token);
}

sub _scan_word {
    my ($self, $str) = @_;
    my ($token, $type, $word);
    $str =~ m/^[a-z_][a-z0-9_]*/i;
    $word = $&;
    if ($word ~~ [KW_COMPOUND]) {
        $type = 'kwcompound';
    } elsif ($word ~~ [KW_SIMPLE]) {
        $type = 'kwsimple';
    } elsif ($word ~~ [KW_LOGIC]) {
        $type = 'kwlogic';
    } elsif ($word ~~ [KW_BOOL]) {
        $type = 'kwbool';
    } elsif ($word ~~ [KW_ERROR]) {
        $type = 'error';
    } else {
        $type = 'identifier';
    }
    $token = {type => $type, value => $word};
    $str = substr $str, length($word);

    return ($str, $token);
}

sub _scan_encloser {
    my ($self, $str) = @_;
    my %enclosers = ('(' => 'roundopen',
                     ')' => 'roundclosed',
                     '{' => 'curlyopen',
                     '}' => 'curlyclosed',
                     '[' => 'squareopen',
                     ']' => 'squareclosed');
    my $char = substr $str, 0, 1;
    my $token = {type => $enclosers{$char}, value => $char};
    $str = substr $str, 1;

    return ($str, $token);
}

sub _scan_seperator {
    my ($self, $str) = @_;
    my %seperators = ('.' => 'dot',
                      ',' => 'comma',
                      ':' => 'collon',
                      ';' => 'semicolon');
    my $char = substr $str, 0, 1;
    my $token = {type => $seperators{$char}, value => $char};
    $str = substr $str, 1;

    return ($str, $token);
}

sub _scan_string {
    my ($self, $str) = @_;
    my $token;
    if ($str =~ m/^u/i || $str =~ m/^u?r?("""|''')/i) {
        # for simplicity unicode and multiline strings are not supported
        $token = {type => 'error'};
    } elsif ($str =~ m/^(r?)"((\\.|.)*?)"/i ||
             $str =~ m/^(r?)'((\\.|.)*?)'/i) {
        # complete string
        $str = substr $str, length($&);
        my $string_value = $2;
        if (lc($1) eq 'r') {
            # raw string
            $string_value = qq('$string_value');
        } else {
            # regular string
            $string_value =~ s/\$/\\\$/g;
            $string_value =~ s/@/\\@/g;
            $string_value = qq("$string_value");
        }
        $token = {type => 'string', value => $string_value};
    } else {
        # incomplete string 
        $token = {type => 'error'};
    }

    return ($str, $token);
}

1;