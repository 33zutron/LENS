#!/usr/bin/env bash
set -xeu

# usage
# ./scripts/validate-compiler-sha.sh [path/to/lens-core]
# Checks if the installed ocamlc compiler SHA matches the opam pin version SHA
# if a path was supplied to a lens-core binary, checks what the binary was
# built with instead.

# optional arg
PATH_TO_LENS_CORE=${1-}

# what we've pinned in opam
SHA_PINNED_IN_OPAM=$(
    opam pin list --normalise |
        grep -oE 'lens/ocaml\.git#[0-9a-f]*' |
        cut -d'#' -f2
)

# the SHA infered from the compiler
SHA_IN_OCAMLC=$(
    opam exec -- ocamlc -version |
        grep -oE "\+lens-fork@[a-f0-9]*" |
        cut -d'@' -f2
)

echo "The SHA infered to be pinned in opam was $SHA_PINNED_IN_OPAM"
echo "The SHA infered from the installed ocamlc compiler was $SHA_IN_OCAMLC"

# check that they are non-empty
if [ -z "$SHA_PINNED_IN_OPAM" ] || [ -z "$SHA_IN_OCAMLC" ]; then
    echo "No SHA could be infered from either ocamlc or opam pin"
    echo "Output from opam pin list --normalise:$(opam pin list --normalise)"
    echo "Output from ocamlc -version:$(opam exec -- ocamlc -version)"
    exit 1
fi

# check that they're equal
if [ "$SHA_PINNED_IN_OPAM" != "$SHA_IN_OCAMLC" ]; then
    echo "They are not equal!"
    exit 1
fi

# if the path to a binary is not provided exit early
if [ -z "$PATH_TO_LENS_CORE" ]; then
    exit 0
fi

# what lens was built with
SHA_LENS_WAS_BUILT_WITH=$(
    ./"$PATH_TO_LENS_CORE" -ocaml_version |
        grep -oE "\+lens-fork@[a-f0-9]*" |
        cut -d'@' -f2
)

echo "The SHA infered from the binary was $SHA_LENS_WAS_BUILT_WITH"

if [ -n "$SHA_LENS_WAS_BUILT_WITH" ] && [ "$SHA_PINNED_IN_OPAM" != "$SHA_LENS_WAS_BUILT_WITH" ]; then
    echo "They are not equal!"
    exit 1
fi
