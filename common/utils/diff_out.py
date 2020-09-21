#!/bin/env python

import sys

def read_lines(name):
    lines = []
    with open(name) as f:
        for l in f:
            if l.strip():
                lines.append(l.strip())
    return lines

def mismatch(dmp_lines, ref_lines):
    print('Mismatch! Output:')
    for l in dmp_lines: print(l)
    print('Expected:')
    for l in ref_lines: print(l)
    sys.exit(-1)

if len(sys.argv) != 3:
    print('diff.py out.txt ref.txt\n')

dmp_lines = read_lines(sys.argv[1])
ref_lines = read_lines(sys.argv[2])

if (len(dmp_lines) != len(ref_lines)):
    mismatch(dmp_lines, ref_lines)

for i in range(len(dmp_lines)):
    dmp = dmp_lines[i]
    ref = ref_lines[i]
    
    if (dmp != ref):
        mismatch(dmp_lines, ref_lines)

