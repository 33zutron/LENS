#
# Copyright (c) 2021-2024 Lens Inc.
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
from lens.config_resolver import ConfigFile
from lens.config_resolver import ConfigLoader

expected_logout_str = "Logged out (log back in with `lens login`)\n"


# it should be ok to logout when not logged in and to logout twice
@pytest.mark.slow
def test_logout_not_logged_in(tmp_path, mocker):
    runner = LensRunner(
        env={"LENS_SETTINGS_FILE": str(tmp_path / ".settings.yaml")},
    )
    result = runner.invoke(cli, subcommand="logout", args=[])
    assert result.exit_code == 0
    assert result.output == expected_logout_str

    # Logout twice should work
    result = runner.invoke(cli, subcommand="logout", args=[])
    assert result.exit_code == 0
    assert result.output == expected_logout_str


# it should fail when run from a non-terminal shell
@pytest.mark.slow
@pytest.mark.osemfail
def test_login_no_tty(tmp_path, mocker):
    runner = LensRunner(
        env={"LENS_SETTINGS_FILE": str(tmp_path / ".settings.yaml")},
        # TODO: not sure why we need use_click_runner here, maybe
        # for the input=fake_key to work?
        use_click_runner=True,
    )
    fake_key = "key123"

    # Fail to login without a tty
    result = runner.invoke(
        cli,
        subcommand="login",
        args=[],
        input=fake_key,
    )
    assert result.exit_code == 2
    assert "lens login is an interactive command" in result.output


# it should login by using LENS_APP_TOKEN
@pytest.mark.slow
@pytest.mark.osemfail
def test_login_env_token(tmp_path, mocker):
    runner = LensRunner(
        env={"LENS_SETTINGS_FILE": str(tmp_path / ".settings.yaml")},
        use_click_runner=True,
    )
    fake_key = "key123"
    alt_key = "key456"

    # Patch Token Validation:
    mocker.patch(
        "lens.app.auth.get_deployment_from_token",
        return_value={"id": 1, "name": "deployment_name"},
    )

    # Login with env token
    result = runner.invoke(
        cli,
        subcommand="login",
        args=[],
        env={"LENS_APP_TOKEN": fake_key},
    )
    assert result.exit_code == 0
    assert result.output.startswith("Saved login token")
    assert "<redacted>" in result.output

    # Login should not fail on second call
    result = runner.invoke(
        cli,
        subcommand="login",
        args=[],
        env={"LENS_APP_TOKEN": alt_key},
    )
    assert result.exit_code == 0
    assert "API token already exists in" in result.output


# it should give access to the registry once logged in
@pytest.mark.slow
@pytest.mark.osemfail
def test_login_and_use_registry(tmp_path, mocker, requests_mock):
    runner = LensRunner(
        env={"LENS_SETTINGS_FILE": str(tmp_path / ".settings.yaml")},
        use_click_runner=True,
    )
    lens_url = "https://lens.dev"
    fake_key = "key123"

    # Patch Token Validation:
    mocker.patch(
        "lens.app.auth.get_deployment_from_token",
        return_value={"id": 1, "name": "deployment_name"},
    )

    result = runner.invoke(
        cli,
        subcommand="login",
        args=[],
        env={"LENS_APP_TOKEN": fake_key},
    )
    assert result.exit_code == 0
    assert result.output.startswith("Saved login token")

    # patch the download of the config to return 401
    requests_mock.get(
        f"{lens_url}/c/r/python.lang.correctness.useless-eqeq.useless-eqeq",
        status_code=401,
        json={"detail": "Invalid API Key"},
    )
    # Run p/ci
    result = runner.invoke(
        cli,
        args=["--config", "r/python.lang.correctness.useless-eqeq.useless-eqeq"],
    )
    assert (
        result.exit_code == 7
    ), "registry should refuse to send rules to invalid token"

    requests_mock.post(
        f"{lens_url}/api/cli/v2/scans",
        status_code=401,
        json={"detail": "Invalid API Key"},
    )
    # Run policy with bad token -> no associated deployment_id
    result = runner.invoke(
        cli, args=["--config", "policy"], env={"LENS_REPO_NAME": "test-repo"}
    )
    assert result.exit_code == 7
    assert "Invalid API Key" in result.output

    mocker.patch("lens.app.auth.get_deployment_id", return_value=1)

    # Run policy without LENS_REPO_NAME
    result = runner.invoke(
        cli,
        args=["--config", "policy"],
    )
    assert result.exit_code == 7
    assert "Need to set env var LENS_REPO_NAME" in result.output

    # Run policy. Check that request is made to correct deployment + org/repo
    mocked_config = mocker.patch.object(
        ConfigLoader,
        "_download_config_from_url",
        side_effect=lambda url: ConfigFile(None, "invalid-conifg}", url),
    )
    result = runner.invoke(
        cli, args=["--config", "policy"], env={"LENS_REPO_NAME": "org/repo"}
    )
    assert result.exit_code == 7
    assert mocked_config.called
    assert "remote-registry was not a mapping" in result.output
