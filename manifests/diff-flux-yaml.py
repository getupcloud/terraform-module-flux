#!/usr/bin/env python3

import yaml, sys
print("loading...")

old=list(yaml.safe_load_all(open(sys.argv[1])))
new=list(yaml.safe_load_all(open(sys.argv[2])))

res={
    'has': [],
    'old_only': [],
    'new_only': []
}

def p(p, o):
    if o['metadata'].get('namespace'):
        print(p, f"{o['metadata']['namespace']} {o['kind']}/{o['metadata']['name']}")
    else:
        print(p, f"{o['kind']}/{o['metadata']['name']}")

def match(o, n):
    if o is None or n is None:
        return False

    if o['kind'] != n['kind']:
        return False

    if o['metadata']['name'] != n['metadata']['name']:
        return False

    if o['metadata'].get('namespace') and n['metadata'].get('namespace'):
        if o['metadata'].get('namespace') != n['metadata'].get('namespace'):
            return False

    return True

def main():
    for o in old:
        if not o:
            continue
        found = False

        for n in new:
            if not match(o, n):
                continue
            found = True
            break

        if found:
            res['has'].append(o)
        else:
            res['old_only'].append(o)

    for n in new:
        if not n:
            continue
        found = False

        for o in old:
            if not match(o, n):
                continue
            found = True
            break

        if not found:
            res['new_only'].append(n)

main()

for i in res['has']:
    p('=', i)

for i in res['old_only']:
    p('-', i)

for i in res['new_only']:
    p('+', i)
