#!/usr/bin/python

#  Prints wondrous sequence, rule as follows: 
#  - if current term is even, next term is half current term
#  - if current term is odd, next term is 3x current term + 1.
#  Return: number of terms

import sys

# Returns True if num is even
def isEven (num):
    if ((num % 2) == 0):
        even = True
    else:
        even = False
    
    return even

def printWondrous (start):
    numTerms = 1;
    term = start;
    
    print term
    while (term > 1):
        if (isEven(term)):
            term = term / 2
        else:
            term = (term * 3) + 1
        
        print term
        numTerms += 1
    
    print

    return numTerms



print "Please enter a start term for wondrous: "
start = sys.stdin.readline()
start = int(start)
printWondrous (start)