#!/usr/bin/python
# taken from
# http://www.pythonforbeginners.com/code-snippets-source-code/python-code-celsius-and-fahrenheit-converter

print "enter a temperature in celsius: \n"
celsius = sys.stdin.readline()
celsius = int(celsius)

fahrenheit = 9.0/5.0 * celsius + 32

print "Temperature:", celsius, "Celsius = ", fahrenheit, " F"