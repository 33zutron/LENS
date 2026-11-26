# OCaml CLI wrapper

_See also the to-do list: [TODO.md](TODO.md)._

This is the temporary home of the OCaml CLI that aims at supplanting
the Python CLI wrapper. This is part of the OCaml code base in the
lens repo. It is a distinct executable from `lens-core` but lives
in the `src/olens` folder for now to avoid massive renames and
difficult git conflicts. We can do this renaming in a short-lived
branch that only handles the renaming.

For now, most of the new code translated from our own Python code base
will be placed under `src/olens`.

## Transition period

During the transition period, we'll have the Python wrapper maintained
in `/cli` and the new OCaml wrapper in `/src/olens`.

### Phase 1: literal translation of essential Python code

In the first phase, all the pytest tests that call the `lens`
command will be modified to call `olens` as well. `olens` will
call OCaml code from lens-core that will be invoked as a library
call.

At the end of this phase, `olens` should implement at least basic
scanning functionality of `lens`, resulting in the non-zero
percentage of successful tests.

This is planned for the first one-two weeks of work, resulting in a
proof-of-concept and better understanding of the project's
feasibility.

Merge the branch at this stage. Then only rename the `/lens-core`
folder to reduce confusion.

### Phase 2: translate the passing pytest tests to OCaml

1. Replicate the testing setup that has been used for the
   Python CLI.
2. Translate the passing tests to OCaml.

This will demonstrate how testing looks with the new OCaml
implementation with no reliance on Python at all.

### Phase 3: feature completion

Translate what remains of the Python implementation to
OCaml. `olens` is now on feature parity with `lens`.

`olens` is now being shipped to users who can choose to use it
instead of `lens`. This is a phase of intense quality assurance for
`olens`.

## Delivery

`olens` becomes `lens`. We stop shipping or maintaining the Python
implementation.

All improvements and fixes are made only to the OCaml implementation.

## Simplifications

This is the phase where duplicate functionality between the wrapper
code and the legacy lens-core code is eliminated. It can be done
incrementally or as needed.
