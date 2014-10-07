#!/usr/bin/python
# Taken from python tutorial
# https://docs.python.org/release/1.5.1p1/tut/functions.html


# write Fibonacci series up to n
def fib(n):    
    #"Print a Fibonacci series up to n"
    a, b = 0, 1
    while b < n:
        print b,
        a, b = b, a+b


fib(2000)
print "^_^"