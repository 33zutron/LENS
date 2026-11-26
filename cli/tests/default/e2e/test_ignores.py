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
import shutil
from pathlib import Path

import pytest
from tests.conftest import mask_variable_text
from tests.conftest import skip_on_windows
from tests.conftest import TARGETS_PATH
from tests.fixtures import RunLens


@pytest.mark.kinda_slow
def test_lensignore(run_lens_in_tmp: RunLens, tmp_path, posix_snapshot):
    (tmp_path / ".lensignore").symlink_to(
        Path(TARGETS_PATH / "ignores" / ".lensignore").resolve()
    )
    # BUG: pylens doesn't complain if an included file is missing
    # This file is included by the .lensignore above.
    # It must be a regular file, not a symlink (enforced in olens).
    shutil.copyfile(
        Path(TARGETS_PATH / "ignores" / ".gitignore"), tmp_path / ".gitignore"
    )

    posix_snapshot.assert_match(
        run_lens_in_tmp("rules/eqeq-basic.yaml", target_name="ignores").stdout,
        "results.json",
    )


# We provide no .lensignore but everything except find.js should still
# be ignored
@pytest.mark.kinda_slow
def test_default_lensignore(run_lens_in_tmp: RunLens, posix_snapshot):
    posix_snapshot.assert_match(
        run_lens_in_tmp(
            "rules/eqeq-basic.yaml", target_name="ignores_default"
        ).stdout,
        "results.json",
    )


# Input from stdin will not have a path that is relative to tmp_path, where we're running lens
@pytest.mark.kinda_slow
@pytest.mark.osemfail
@skip_on_windows  # fix masking code in test output
def test_file_not_relative_to_base_path(run_lens: RunLens, posix_snapshot):
    results = run_lens(
        options=["--json", "-e", "a", "--lang", "js", "-"],
        stdin="a",
        use_click_runner=True,  # TODO: probably because of stdin?
    )
    results.raw_stdout = mask_variable_text(results.raw_stdout)
    posix_snapshot.assert_match(results.as_snapshot(), "results.txt")
