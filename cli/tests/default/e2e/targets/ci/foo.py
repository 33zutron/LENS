# Used by test_ci.py

def bar():
    a == a
    a == a
    a == a  # nolens
    a == a

    x == x  # nolens

    y == y

    z == z  # nolens

    x == 5
    y == 5  # nolens

    baz == 4  # nolens
    baz == 4

    potato == 3

    b == b # Triage ignored by syntactic_id
    a == a # Triage ignored by match_based_id

    d2 = danger
    sink(d2)
