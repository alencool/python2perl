#!/usr/bin/python
# testing stdin and line continuation
import sys

print "Enter a number:"
num = sys.stdin.readline()
num = int(num)

if num == 42:
    print "The Answer to the Ultimate Question of Life, the Universe, \
            and Everything"
else:
    print "%d must be your lucky number" % num
