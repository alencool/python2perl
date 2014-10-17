#!/usr/bin/perl -w
#
#   Date: 6.10.14
#   Author: Alen Bou-Haidar
#

use strict;
use Lexer;
use Parser;


my @lines = <>;
my $lexer = new Lexer;
$lexer->tokenize(@lines);
my $parser = new Parser;
my $tree = $parser->parse($lexer);
print $tree->to_string;
