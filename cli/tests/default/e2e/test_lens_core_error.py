#
# Copyright (c) 2024-2025 Lens Inc.
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
import pytest
from tests.fixtures import RunLens

from lens.constants import OutputFormat


# it should not fail the whole scan for unhandled exn (e.g., r2c_was_fatal)
# that could still be attached to a file in lens-core
@pytest.mark.kinda_slow
def test_exit_code_warning_error(run_lens_in_tmp: RunLens):
    stdout, stderr = run_lens_in_tmp(
        config=f"rules/stuff_stmt.yaml",
        target_name=f"error_management/r2c_was_fatal.py",
        options=["--verbose"],
        output_format=OutputFormat.TEXT,
        strict=False,
        assert_exit_code=0,
    )


# it should fail the scan if using --strict though
@pytest.mark.kinda_slow
def test_exit_code_with_strict(run_lens_in_tmp: RunLens):
    stdout, stderr = run_lens_in_tmp(
        config=f"rules/stuff_stmt.yaml",
        target_name=f"error_management/r2c_was_fatal.py",
        options=["--verbose"],
        output_format=OutputFormat.TEXT,
        strict=True,
        assert_exit_code=2,
    )


# it should not fail the whole scan for exn in a post processor (e.g., nolens)
@pytest.mark.kinda_slow
def test_error_management_post_processor(run_lens_in_tmp: RunLens):
    stdout, stderr = run_lens_in_tmp(
        config=f"rules/stuff_stmt.yaml",
        target_name=f"error_management/r2c_nolens_was_fatal.py",
        options=["--verbose"],
        output_format=OutputFormat.TEXT,
        strict=False,
        assert_exit_code=0,
    )
