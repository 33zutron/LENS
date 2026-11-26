#
# Copyright (c) 2022-2024 Lens Inc.
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
from pathlib import Path

import pytest
from tests.conftest import TARGETS_PATH
from tests.lens_runner import LensRunner

from lens.cli import cli


@pytest.mark.kinda_slow
# osemfail, but now translated to Test_publish_subcommand.ml
@pytest.mark.osemfail
def test_publish(tmp_path, mocker):
    runner = LensRunner(
        env={"LENS_SETTINGS_FILE": str(tmp_path / ".settings.yaml")},
        use_click_runner=True,
    )

    tests_path = Path(TARGETS_PATH / "lens-publish" / "valid")
    valid_target = str(tests_path.resolve())
    valid_single_file_target = str((tests_path / "valid1.yaml").resolve())

    # should require login
    result = runner.invoke(
        cli,
        subcommand="publish",
        args=[valid_target],
    )
    assert result.exit_code == 2
    assert result.output == "run `lens login` before using upload\n"

    mocker.patch(
        "lens.app.auth.get_deployment_from_token",
        return_value={"id": 1, "name": "deployment_name"},
    )

    # log back in
    result = runner.invoke(
        cli, subcommand="login", args=[], env={"LENS_APP_TOKEN": "fakeapitoken"}
    )
    assert result.exit_code == 0

    # fails if no rule specified
    result = runner.invoke(cli, subcommand="publish", args=[])
    assert result.exit_code == 2

    # fails if invalid rule specified
    result = runner.invoke(
        cli,
        subcommand="publish",
        args=[
            str(Path(TARGETS_PATH / "lens-publish" / "invalid").resolve()),
        ],
    )
    assert result.exit_code == 2
    assert "Invalid rule definition:" in result.output

    # fails if a yaml with more than one rule is specified
    result = runner.invoke(
        cli,
        subcommand="publish",
        args=[
            str(Path(TARGETS_PATH / "lens-publish" / "multirule").resolve()),
        ],
    )
    assert result.exit_code == 2
    assert (
        "Rule contains more than one rule: only yaml files with a single can be published"
        in result.output
    )

    # fails if --visibility=public without --rule-id
    result = runner.invoke(
        cli,
        subcommand="publish",
        args=["--visibility=public", valid_target],
    )
    assert result.exit_code == 2
    assert (
        "Only one public rule can be uploaded at a time: specify a single Lens rule"
        in result.output
    )

    result = runner.invoke(
        cli,
        subcommand="publish",
        args=["--visibility=public", valid_single_file_target],
    )
    assert result.exit_code == 2
    assert "--visibility=public requires --registry-id" in result.output
