#!/usr/bin/python
# testing lists

l =[1,2,3]
print len(l)

l += [4,5,6]
print len(l)

for i in range(6):
    l.pop();

print len(l);

for i in range(10):
    l.append(i);

print l[2:4]