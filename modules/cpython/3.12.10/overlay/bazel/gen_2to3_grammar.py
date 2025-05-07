# gen_2to3_grammar.py: input

import sys

from lib2to3.pgen2 import driver

gp = driver._generate_pickle_name(sys.argv[1])
driver.load_grammar(sys.argv[1], gp, force=True)
print(gp)
