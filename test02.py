#!/usr/bin/python
# testing if else statments

a = 1
b = 4

if (a < b):
    print "first level"
    if (a > b):
        print "this shouldn't print"
    elif 5 < b:
        print "not this either"
    else:
        print "The only choice left"
else:
    print "<_<"