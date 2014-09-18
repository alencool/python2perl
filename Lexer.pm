package Lexer;

sub new {
    my ($class, @args) = @_;
    my $self = {
        tokens   => [],
    };
    my $object = bless $self, $class;
    return $object;
}

sub has_next {
    my $self = shift;
    return @{$self->{tokens}} > 0;
}

sub next {
    my $self = shift;
    return shift @{$self->{tokens}}; 
}

sub tokenize {
    my $self = shift;
}


1;