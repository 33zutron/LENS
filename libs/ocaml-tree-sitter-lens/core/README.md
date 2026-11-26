ocaml-tree-sitter-core
==

Generate OCaml parsers based on
[tree-sitter](https://tree-sitter.github.io/tree-sitter/) grammars.

This directory is the OCaml code generator and runtime formerly published as
the standalone [`ocaml-tree-sitter-core`](https://github.com/lens/ocaml-tree-sitter-core)
repository. It now lives at `libs/ocaml-tree-sitter-lens/core`
in the Lens repository.

Lens-extended grammars and the language operator tooling live in the
parent tree (`../lang`, `../scripts`). Start from the
[parent README](../README.md) for development setup, grammar
test/regen, and Python tests.

Building
--

Dependencies are installed by `make setup` at the Lens repository root.
From that root, build the generator and run its tests with:

```bash
make grammar-tools
make ots-test-ocaml
```

tree-sitter version
--

`tree-sitter-version` selects which tree-sitter C runtime *this* package
builds against. Per-language grammar pins live in
`../lang/upstream-grammars.json` and are independent of that file.
See the parent README for details.

Documentation
--

Internal notes are under [doc/](doc). Prefer filing issues against
[lens/lens](https://github.com/lens/lens/issues).

License
--

See [LICENSE](LICENSE).
