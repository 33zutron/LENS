def foo1():
    stuff()

def foo2():
    # nolens: stuff
    stuff()
    
def foo3():
    # nolens: nolens_r_2_c_was_fatal
    stuff()
