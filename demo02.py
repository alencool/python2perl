#!/usr/bin/python
# sorting numbers

numbers = [40, 1, 20, 33, 3, 11, 12, 4, 27, 22]

for i in range(40):
    if i not in numbers:
        numbers.append(i)

numbers = sorted(numbers)   # sort number
for i in numbers:
    #print i amount of i
    print 'x' * i
