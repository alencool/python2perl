#!/usr/bin/python
# test split join

sentence = "the,cat,sat,on,the,mat"
words =  sentence.split(',')
print words

joined = ' '.join(words)
print joined