#!/usr/bin/python

# Prints the Danish flag in ascii
import sys

def showPixel(col, row):
    if ((row != 2) and (col != 2)):
        pixel = '*'  
    else:
        pixel = ' '
    
    sys.stdout.write(pixel)


def showDanish ():

    row = 0
    col = 0
    
    while (row < 5):
        col = 0
        while (col < 12):
            showPixel (col, row)
            col += 1
        sys.stdout.write("\n")
        row += 1


showDanish()