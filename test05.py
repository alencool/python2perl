#!/usr/bin/python
#testing hashes


h = {'alen': 74, 'pascal': 45, 'mario': 26, 'sam': 24}

keys = h.keys();

keys = sorted(keys)

for k in keys:
    print k, keys[k]

if 'alen' in h:
    print "alen is a key"