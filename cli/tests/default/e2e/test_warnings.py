#
# Copyright (c) 2025 Lens Inc.
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
# Test various warnings and error messages
import pytest
from tests.fixtures import RunLens

from lens.constants import OutputFormat


@pytest.mark.kinda_slow
@pytest.mark.osemfail
def test_lensignore_v2_warning(
    run_lens_on_copied_files: RunLens, posix_snapshot
):
    """Check that '--lensignore-v2' prints a deprecation warning"""
    posix_snapshot.assert_match(
        run_lens_on_copied_files(
            config="rules/eqeq.yaml",
            target_name="basic",
            output_format=OutputFormat.TEXT,
            options=["--lensignore-v2"],
        ).stderr,
        "results.txt",
    )
