#!/usr/bin/python
# testing files

f = open('secret_doc.txt', 'w')
f.write('whispher whisper');
f.close()


f = open('secret_doc.txt')
secret = f.readline()
print secret
f.close()