#!/usr/bin/python

import sys


print "please enter the year you are interested in\n"
year = sys.stdin.readline()
year = int(year)

if ((year % 400) == 0):
    print "%d is a leap year!\n" % year
elif ((year % 100) == 0):
    print "%d is not a leap year!\n" % year
elif ((year % 4) == 0):
    print "%d is a leap year!\n" % year
else:
    print "%d is not a leap year!\n" % year
