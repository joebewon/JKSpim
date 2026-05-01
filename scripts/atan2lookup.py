from math import atan2, degrees
import os

base = os.path.dirname(__file__)
path = os.path.join(base, 'output', "atan2lookup.txt")
bound: int = 300

with open(path, 'w') as f:
    print('.data\n.align 4')
    f.write('.data\n.align 4\natan2lookup_begin:')

    # Top
    for x in range(-bound, 0):
        f.write(f'\n.word ')
        for y in range(-bound, bound + 1):
            theta = int(round(degrees(atan2(x, y)), 1))
            f.write(f"{theta} ")
            print(theta, end="\t")

        print('')

    # First half of the middle line
    f.write('\n.word ')
    for y in range(-bound, 0):
        theta = int(round(degrees(atan2(0, y)), 1))
        f.write(f"{theta} ")
        print(theta, end="\t")

    # Second half of the middle line
    print('')
    f.write('\natan2lookup:\n.word ')
    for y in range(0, bound + 1):
        theta = int(round(degrees(atan2(0, y)), 1))
        f.write(f"{theta} ")
        print(theta, end="\t")

    # Bottom
    print('')
    for x in range(1, bound + 1):
        f.write("\n")
        f.write(f'.word ')
        for y in range(-bound, bound + 1):
            theta = int(round(degrees(atan2(x, y)), 1))
            f.write(f"{theta} ")
            print(theta, end="\t")

        print('')
