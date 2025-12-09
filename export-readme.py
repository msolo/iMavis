#!/usr/bin/env python3

import re
import sys


def test():
    sl = [
        'a href="text.html"',
        'a href="../updir"',
        'a href="https://example.com"',
        '<img srcset="img/crap.gif"',
    ]
    for s in sl:
        s2 = pattern1.sub(repl1, s)
        print(s2)


def repl1(m):
    if not m.group(2).startswith(("http", "/", ".")):
        return '%s="docs/%s' % (m.group(1), m.group(2))
    return m.group(0)


def repl2(m):
    if not m.group(1).startswith(("http", "/", ".")):
        return "](docs/%s" % m.group(1)
    return m.group(0)


pattern1 = re.compile('(href|src|srcset)="([^"]+)')
pattern2 = re.compile("\\]\\(([^\\)]+)")


def main():
    with open(sys.argv[1]) as fin:
        with open(sys.argv[2], "w") as fout:
            s = fin.read()
            s = pattern1.sub(repl1, s)
            s = pattern2.sub(repl2, s)
            fout.write(s)


main()
