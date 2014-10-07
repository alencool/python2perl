#!/usr/bin/python
# test regular expressions

import re

# matching
m = re.match(r"(\d+)\.(\d+)", "18.1632")
integer = m.group(1)
fraction = m.group(2)
print "Int:%s Frac:%s" % (integer, fraction)



# subbing
line  = 'The cat sat on a hat'
line = re.sub(r'cat', 'dog', line)
line = re.sub(r'hat', 'watermelon', line)
print line

