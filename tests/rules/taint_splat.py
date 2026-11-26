# https://github.com/returntocorp/lens/issues/6920
def taint_test(param1):
    x = tainted
    #ruleid: test
    sink(x)
    #ruleid: test
    sink(*x)
    #ruleid: test
    sink(**x)
