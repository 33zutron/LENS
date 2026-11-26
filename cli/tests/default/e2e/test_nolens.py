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
import pytest
from tests.conftest import _clean_stdout
from tests.conftest import skip_on_windows
from tests.fixtures import RunLens


@pytest.mark.kinda_slow
def test_regex_rule__nolens(run_lens_in_tmp: RunLens, posix_snapshot):
    posix_snapshot.assert_match(
        run_lens_in_tmp(
            "rules/regex/regex-nolens.yaml", target_name="basic/regex-nolens.txt"
        ).stdout,
        "results.json",
    )


@pytest.mark.kinda_slow
def test_nosem_rule(run_lens_in_tmp: RunLens, posix_snapshot):
    posix_snapshot.assert_match(
        run_lens_in_tmp("rules/nosem.yaml").stdout, "results.json"
    )


@pytest.mark.kinda_slow
@pytest.mark.osemfail
@skip_on_windows  # better backslash replacement logic
def test_nosem_rule__invalid_id(run_lens_in_tmp: RunLens, posix_snapshot):
    stdout, stderr = run_lens_in_tmp(
        "rules/nosem.yaml", target_name="nosem_invalid_id", assert_exit_code=2
    )

    posix_snapshot.assert_match(stderr, "error.txt")
    posix_snapshot.assert_match(_clean_stdout(stdout), "error.json")


@pytest.mark.kinda_slow
def test_nosem_with_multiple_ids(run_lens_in_tmp: RunLens):
    run_lens_in_tmp(
        "rules/two_matches.yaml",
        target_name="nolens/multiple-nolens.py",
        assert_exit_code=0,
    )


@pytest.mark.kinda_slow
def test_nosem_rule__with_disable_nosem(run_lens_in_tmp: RunLens, posix_snapshot):
    posix_snapshot.assert_match(
        run_lens_in_tmp("rules/nosem.yaml", options=["--disable-nosem"]).stdout,
        "results.json",
    )


# Regression for the --error exit-code path: on a target with only
# nolens-suppressed matches, --disable-nosem should treat them as real
# findings (user explicitly opted out of suppression) and exit non-zero.
@pytest.mark.kinda_slow
def test_disable_nosem_error_exit_on_suppressed_only_target(
    run_lens_in_tmp: RunLens,
):
    run_lens_in_tmp(
        "rules/nosem.yaml",
        target_name="nosem_only/suppressed-only.py",
        options=["--disable-nosem", "--error"],
        assert_exit_code=1,
    )
