#!/usr/bin/python
# testing concatination

m = 'hello ' + 'world'
m += '!'
print m

b = [3,4,4,5]
c = [1,2,3,4] + [8,7,6]
d = b + c
print len(d)