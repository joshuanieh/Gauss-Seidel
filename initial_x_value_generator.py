import random

for i in range(16):
    print(f'x_r[{i+1}] <= 32\'b', "{:032b}".format(random.randint(0, 2**32-1)), ";", sep='')