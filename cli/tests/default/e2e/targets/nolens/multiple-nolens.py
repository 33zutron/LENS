def foo(a, b):
    return foo(bar(1)) # nolens: rules.match-foo, rules.match-bar