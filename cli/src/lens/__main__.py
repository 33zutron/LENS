#!/usr/bin/env python3
import sys

if __name__ == "__main__":
    sys.stderr.write(
        "Using `python -m lens` to run Lens is deprecated as of 1.38.0. Please simply run `lens` instead.\n"
    )
    sys.exit(2)
