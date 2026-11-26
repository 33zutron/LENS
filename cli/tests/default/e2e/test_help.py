#
# Copyright (c) 2022-2025 Lens Inc.
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
from tests.lens_runner import LensRunner

from lens.cli import cli


@pytest.mark.quick
@pytest.mark.parametrize("help_flag", ["--help", "-h"])
def test_help_text(tmp_path, posix_snapshot, help_flag):
    """
    Test to make sure top level help text doesn't change unintentionally
    """
    runner = LensRunner(
        env={"LENS_SETTINGS_FILE": str(tmp_path / ".settings.yaml")}
    )
    result = runner.invoke(cli, args=[help_flag], env={})
    posix_snapshot.assert_match(result.output, "help.txt")
