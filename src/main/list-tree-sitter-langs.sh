#! /usr/bin/env bash
#
# List of tree-sitter parsers into a config file
# This runs from the project root and looks for tree-sitter parsers
# in the standard locations.
#
set -eu

# Paths are relative to the project root which can be
# lens, lens-proprietary, or lens-proprietary/OSS depending
# on context.
paths=$(echo languages/*/tree-sitter/lens-*)

# Extract 'some_lang' from folders named 'lens-some-lang'
for path in $paths; do
  lens_lang=$(basename "$path")
  echo "${lens_lang#lens-}" | tr '-' '_' | sort
done
