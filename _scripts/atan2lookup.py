from math import atan2, degrees
import os

base = os.path.dirname(__file__)
path = os.path.join(base, 'output', "Atan2lookup.s")
bound: int = 300
directive = '.half'

with open(path, 'w') as f:
    print('.data\n.align 2')
    f.write('.data\n.align 2\natan2lookup_begin:')

    # Top
    for x in range(-bound, 0):
        f.write(f'\n    {directive} ')
        for y in range(-bound, bound + 1):
            theta = int(round(degrees(atan2(y, x))))
            f.write(f"{theta} ")
            print(theta, end="\t")

        print('')

    # First half of the middle line
    f.write(f'\n    {directive} ')
    for y in range(-bound, 0):
        theta = int(round(degrees(atan2(y, 0)), 1))
        f.write(f"{theta} ")
        print(theta, end="\t")

    # Second half of the middle line
    print('')
    f.write(f'\natan2lookup:\n    {directive} ')
    for y in range(0, bound + 1):
        theta = int(round(degrees(atan2(y, 0)), 1))
        f.write(f"{theta} ")
        print(theta, end="\t")

    # Bottom
    print('')
    for x in range(1, bound + 1):
        f.write("\n")
        f.write(f'    {directive} ')
        for y in range(-bound, bound + 1):
            theta = int(round(degrees(atan2(y, x)), 1))
            f.write(f"{theta} ")
            print(theta, end="\t")

        print('')
    f.write('\n##### End arctan2 lookup table #####')