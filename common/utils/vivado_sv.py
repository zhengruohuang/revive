#!/bin/env python

import os
import sys

def read_preprocessed(path):
    lines = []
    with open(os.path.join(path, 'preprocessed.sv')) as f:
        for l in f:
            lines.append(l)
    return lines

def strip_and_save(lines, path, name):
    # t - text, e - empty
    mode = 't'
    
    with open(os.path.join(path, name), 'w') as f:
        for l in lines:
            if l.startswith('`line '):
                mode = 'e'
            elif l.strip() == '':
                if mode == 't':
                    f.write('\n')
                mode = 'e'
            else:
                f.write(l.rstrip() + '\n')
                mode = 't'

def split_top_and_modules(lines):
    top_lines = []
    modules_lines = []
    
    # t - top, m - modules
    mode = 'm'
    
    for l in lines:
        if l.startswith('module revive '):
            mode = 't'
        elif l.startswith('endmodule') and mode == 't':
            mode = 't_m'
        elif mode == 't_m':
            mode = 'm'
        
        if mode == 'm':
            modules_lines.append(l)
        elif mode == 't' or mode == 't_m':
            top_lines.append(l)
    
    return (top_lines, modules_lines)

base_path = sys.argv[1]

lines = read_preprocessed(base_path)
(top_lines, modules_lines) = split_top_and_modules(lines)
strip_and_save(top_lines, base_path, 'top.sv')
strip_and_save(modules_lines, base_path, 'modules.sv')

