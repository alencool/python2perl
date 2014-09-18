#!/usr/bin/perl
# Starting point for COMP2041/9041 assignment 
# http://www.cse.unsw.edu.au/~cs2041/assignments/python2perl
# written by andrewt@cse.unsw.edu.au September 2014

while ($line = <>) {
	if ($line =~ /^#!/ && $. == 1) {
	
		# translate #! line 
		
		print "#!/usr/bin/perl -w\n";
	} elsif ($line =~ /^\s*#/ || $line =~ /^\s*$/) {
	
		# Blank & comment lines can be passed unchanged
		
		print $line;
	} elsif ($line =~ /^\s*print\s*"(.*)"\s*$/) {
	
		# Python's print print a new-line character by default
		# so we need to add it explicitly to the Perl print statement
		
		print "print \"$1\\n\";\n";
	} else {
	
		# Lines we can't translate are turned into comments
		
		print "#$line\n";
	}
}