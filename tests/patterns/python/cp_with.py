# https://github.com/returntocorp/lens/issues/3402

def test1():
    hardcoded = "hello"
    with something() as foobar:
	#ERROR:
        print(hardcoded)
