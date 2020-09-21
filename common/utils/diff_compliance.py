#!/bin/env python

import sys

def read_lines(name):
    lines = []
    with open(name) as f:
        for l in f:
            if l.strip():
                lines.append(l.strip())
    return lines

if len(sys.argv) != 3:
    print('diff.py dump.txt reference.txt\n')

dmp_lines = read_lines(sys.argv[1])
ref_lines = read_lines(sys.argv[2])

err = False

for i in range(len(ref_lines)):
    ref = ref_lines[i]
    if i >= len(dmp_lines):
        print('Missing test #{0}, ref: {1}'.format(i, ref))
        err = True
        continue
    
    dmp = dmp_lines[i]
    if dmp != ref:
        print('Mismatch @ test #{0}, dump: {1}, ref: {2}'.format(i, dmp, ref))
        err = True

if len(dmp_lines) > len(ref_lines):
    for i in range(len(ref_lines), len(dmp_lines)):
        dmp = dmp_lines[i]
        print('Unknown extra test #{0}, dmp: {1}'.format(i, dmp))
        err = True

if (err):
    sys.exit(-1)

