#
# Copyright (c) 2021-2025 Lens Inc.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# version 2.1 as published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the file
# LICENSE for more details.
#
class LensVariant:
    def __init__(self, name: str, lens_core_extra: str, lens_extra: str = ""):
        # name for the input corpus (rules and targets)
        self.name = name

        # space-separated extra arguments to pass to lens-core
        # command via LENS_CORE_EXTRA environment variable
        self.lens_core_extra = lens_core_extra

        # space-separated extra arguments to pass to the default lens
        # command
        self.lens_extra = lens_extra


# Feel free to create new variants. The idea is to use the default set
# of options as the baseline and we see what happens when we enable or
# disable this or that optimization.
#
from constants import STD

LENS_VARIANTS = [
    # default settings
    LensVariant(STD, ""),
    LensVariant("no-filter-irrelevant-rules", "-no_filter_irrelevant_rules"),
]

# For when you just want to test a single change
STD_VARIANTS = [LensVariant(STD, "")]
