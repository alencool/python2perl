#!/usr/bin/python
#Taken from https://wiki.python.org/moin/SimplePrograms


sing = "%d bottles of beer on the wall,\n\
%d bottles of beer,\n\
take one down, pass it around,\n\
%d bottles of beer on the wall!"

bottles_of_beer = 99
while bottles_of_beer > 1:
    print sing % (bottles_of_beer, bottles_of_beer,
        bottles_of_beer - 1)
    bottles_of_beer -= 1
