#
# Copyright (c) 2023-2024 Lens Inc.
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
import re
import subprocess

import pytest
from tests.lens_runner import LENS_BASE_SCAN_COMMAND

# used to be in e2e/test_utility_commands.py


@pytest.mark.kinda_slow
@pytest.mark.osemfail
def test_dump_command_for_core():
    lens_core_command = subprocess.check_output(
        LENS_BASE_SCAN_COMMAND
        + [
            "--config",
            "tests/default/e2e/rules/eqeq-basic.yaml",
            "tests/default/e2e/targets/basic",
            "-d",
        ],
        encoding="utf-8",
    )

    result = subprocess.run(lens_core_command, shell=True)

    assert result.returncode == 0


@pytest.mark.kinda_slow
@pytest.mark.osemfail
def test_dump_engine():
    result = subprocess.check_output(
        LENS_BASE_SCAN_COMMAND + ["--dump-engine-path"],
        encoding="utf-8",
    )

    assert re.match(r"/[\w/\_\-\.]+/lens-core", result)
