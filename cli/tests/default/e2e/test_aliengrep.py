#
# Copyright (c) 2023-2025 Lens Inc.
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
# Test aliengrep integration in Lens rules
import pytest
from tests.fixtures import RunLens


@pytest.mark.kinda_slow
@pytest.mark.parametrize(
    "rule,target",
    [
        # Various real-world tests adapted from spacegrep tests.
        ("rules/aliengrep/html.yaml", "aliengrep/html.mustache"),
        ("rules/aliengrep/markdown.yaml", "aliengrep/markdown.md"),
        ("rules/aliengrep/httpresponse.yaml", "aliengrep/httpresponse.txt"),
        ("rules/aliengrep/dockerfile.yaml", "aliengrep/dockerfile"),
        ("rules/aliengrep/multi-lines.yaml", "aliengrep/multi-lines.java"),
        ("rules/aliengrep/terraform.yaml", "aliengrep/terraform.tf"),
        # Aliengrep-specific tests
        ("rules/aliengrep/begin-end.yaml", "aliengrep/begin-end.log"),
        ("rules/aliengrep/long-match.yaml", "aliengrep/long-match.txt"),
        (
            "rules/aliengrep/metavariable-pattern.yaml",
            "aliengrep/metavariable-pattern.conf",
        ),
    ],
)
def test_aliengrep(run_lens_in_tmp: RunLens, posix_snapshot, rule, target):
    posix_snapshot.assert_match(
        run_lens_in_tmp(rule, target_name=target).stdout,
        "results.json",
    )


@pytest.mark.kinda_slow
@pytest.mark.parametrize(
    "rule,target",
    [
        ("rules/aliengrep/nosem-html.yaml", "aliengrep/nosem.html"),
    ],
)
def test_aliengrep_nosem(run_lens_in_tmp: RunLens, posix_snapshot, rule, target):
    posix_snapshot.assert_match(
        run_lens_in_tmp(
            rule, target_name=target, options=["--no-rewrite-rule-ids"]
        ).stdout,
        "results.json",
    )
