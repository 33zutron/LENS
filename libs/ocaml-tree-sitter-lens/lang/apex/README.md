About the Apex language integration
===================================

We use the project called
[sfapex](https://github.com/aheber/tree-sitter-sfapex) by @aheber.
The Apex language comprises sublanguages called SOSL and SOQL. These
grammars are defined separately in the sfapex project and each has its
own test suite.

Testing
-------

Use `sfapex`, not `apex` when running `./test-lang`:
```
./test-lang sfapex
```

This will run tests for the 3 sublanguages `sosl`, `soql`, and `apex`.
The final product used by the `lens` repo is the extended
`apex` grammar: `lens-apex`.

Extending the grammar with Lens constructs
---------------------------------------------

It's probably simpler to have all the extensions defined in
`lang/lens-grammars/src/lens-sfapex/apex/grammar.js`, including
the extensions of SOSL and SOQL.
