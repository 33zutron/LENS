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
#
# Test target selection before any rule or language-specific filtering
#
import os
import shutil
import sys
from dataclasses import dataclass
from dataclasses import field
from enum import Enum
from pathlib import Path
from typing import List
from typing import Optional
from typing import Set

import pytest
from tests.conftest import skip_on_windows
from tests.fixtures import RunLens


# Specify how to download the test project
@dataclass
class GitProject:
    name: str
    # The git project URL (not the web page)
    url: str
    # SHA1 commit ID
    commit: str


# Identify how the repo should be set up and scanned by lens
class Config(Enum):
    # git: a git project scanned with the default lens options
    GIT = "git"

    # git: list only the files that changed (modified or added) since
    # a particular commit (actually since the more recent common ancestor
    # of HEAD and that commit, known as the merge base).
    GIT_BASELINE_COMMIT = "git_baseline_commit"

    # novcs: the same project from which '.git' was removed, scanned with
    # the default lens options
    NOVCS = "novcs"

    # ignoregit: run on the git project with the '--no-git-ignore' option
    # (does several things that are not obvious from its name)
    IGNOREGIT = "ignoregit"

    # default ignores: test a project that doesn't have .lensignore files
    GIT_DEFAULT_LENSIGNORE = "git_default_lensignore"
    NOVCS_DEFAULT_LENSIGNORE = "novcs_default_lensignore"

    # test a blank .lensignore
    GIT_EMPTY_LENSIGNORE = "git_empty_lensignore"
    NOVCS_EMPTY_LENSIGNORE = "novcs_empty_lensignore"

    # test --exclude options with an empty .lensignore
    GIT_EXCLUDE = "git_exclude"
    NOVCS_EXCLUDE = "novcs_exclude"

    # test --include options with an empty .lensignore
    GIT_INCLUDE = "git_include"
    NOVCS_INCLUDE = "novcs_include"

    # test --x-lensignore-filename
    ALT_LENSIGNORE = "alt_lensignore"


# The expectations regarding a particular target file path
#
# The expectations for olens and for pylens --lensignore-v2 are
# the same.
#
@dataclass
class Expect:
    selected: bool
    selected_by_pylens: Optional[bool] = None
    selected_by_olens: Optional[bool] = None
    ignore_pylens_result: bool = False
    ignore_olens_result: bool = False
    paths: List[str] = field(default_factory=lambda: [])


# This is an artificial git project that offers all the difficulties we could
# think of for file targeting.
#
# Do we need to run on several projects?
PROJECT = GitProject(
    name="lens-test-project1",
    url="https://github.com/lens/lens-test-project1.git",
    commit="b1d5bc05d9cce652746c62bf221483d61a8adc73",
)


def is_git_project(config: Config) -> bool:
    if config is Config.GIT or config is Config.IGNOREGIT:
        return True
    else:
        return False


# Check whether a target path was selected or ignored by lens, depending
# the expectation we have.
#
def check_expectation(
    *,
    expect: Expect,
    is_running_olens: bool,
    config: Config,
    selected_targets: Set[str],
):
    # TODO: remove requested_lensignore_v2 since it's now always true
    requested_lensignore_v2 = True

    # Convert path to use OS's correct path separator
    paths = [str(Path(path)) for path in expect.paths]

    # We expect lensignore v2 behavior if we call olens directly or
    # via the --use-lensignore-v2 option.
    v2 = is_running_olens or requested_lensignore_v2
    rpc = requested_lensignore_v2 and not is_running_olens

    if v2 and expect.ignore_olens_result:
        return
    if not v2 and expect.ignore_pylens_result:
        return

    expect_selected = expect.selected
    if v2 and expect.selected_by_olens is not None:
        expect_selected = expect.selected_by_olens
    if not v2 and expect.selected_by_pylens is not None:
        expect_selected = expect.selected_by_pylens

    label = "[olens]" if is_running_olens else "[pylens]"
    label = label + " [rpc]" if rpc else " [no rpc]"
    label = label + (f" [{config.value}]")
    for path in paths:
        # Sanity checks (important when checking that a path is not selected)
        if not os.path.lexists(path):
            raise Exception(f"path {path} doesn't exist in the file system!")
        # Tests
        if expect_selected:
            msg = f"{label} check that target path was selected: {path}"
            print(msg, file=sys.stderr)
            assert path in selected_targets, msg
        else:
            msg = f"{label} check that target path was ignored: {path}"
            print(msg, file=sys.stderr)
            assert path not in selected_targets, msg


# What we expect from lens when running with the most common invocation i.e.
#
# - run lens from the project root
# - run lens on the project root
# - no optional command-line flags
# - shared expectations in git and novcs projects
#
# To cover a new test case, add a file to the test repo and specify
# the expectations for the new path below.
#
COMMON_EXPECTATIONS = [
    Expect(
        selected=True,
        paths=[
            # Paths that are correctly selected by both pylens and olens
            ".gitignore",
            ".gitmodules",
            ".lensignore",
            "README.md",
            "gitignored-only-in-src-and-below.py",
            "gitignored-only-in-src.py",
            "hello.py",
            "img/hello.svg",
            "lensignored/hello.py",
            "lensignored-folder",
            "lensignored-only-in-src-and-below.py",
            "lensignored-only-in-src.py",
            "lensignored-py-contents/hello.rb",
            "src/.gitignore",
            "src/.hidden.py",
            "src/.lensignore",
            "src/10KiB.py",
            "src/hello.py",
            "src/lensignored-at-root/scanme",
            "src/lensignored-root",
            "src/lensignored-root-folder/hello.py",
            "src/lensignored-py-contents/hello.rb",
            "src/src/lensignored-anchored/hello.py",
            "src/subdir/gitignored-only-in-src.py",
            "src/subdir/lensignored-only-in-src.py",
            "tests/hello.py",
            # special characters in file names
            "src/~",
            "src/quote'/hello.py",
            "src/space !/hello.py",
            "src/🚀.py",
            # sanity check for dotfiles/
            "dotfiles/not-excluded",
            # Control for backward compatibility with Lensignore v1
            "normalized-patterns/not-excluded-for-v1-compatibility",
        ],
    ),
    Expect(
        selected=False,
        paths=[
            # Paths that are correctly ignored by both pylens and olens
            "img/red.png",
            "lensignored-everywhere/hello.py",
            "lensignored-root",
            "lensignored-root-folder/hello.py",
            "src/broken-symlink.py",
            "src/lensignored-everywhere/hello.py",
            "src/lensignored-folder/hello.py",
            "src/lensignored-py-contents/hello.py",
            "src/symlink.py",
            "src/lensignored-via-include.py",
            "linux/link-to-file-in-dir-without-read-perm",
            # in Gitignore, wildcards can match leading periods
            "dotfiles/excluded.py",
            "dotfiles/.excluded.py",
            "dotfiles/_excluded.rb",
            "dotfiles/.excluded.rb",
            # Backward compatibility with Lensignore v1 (deprecated)
            "normalized-patterns/excluded-for-v1-compatibility",
        ],
    ),
    # accepted differences between pylens and olens
    Expect(
        # excluded by olens, selected by pylens
        selected=False,
        selected_by_pylens=True,
        paths=[
            # pylens doesn't consult .lensignore files in subfolders:
            "src/lensignored-only-in-src-and-below.py",
            "src/lensignored-only-in-src.py",
        ],
    ),
    # pylens bugs
    Expect(
        selected=False,
        selected_by_pylens=True,
        paths=[
            "lensignored-py-contents/hello.py",
            "lensignored-at-root/ignoreme",
        ],
    ),
]

GIT_PROJECT_EXPECTATIONS = [
    # common expectations for a git project (but not for a novcs project)
    Expect(
        selected=False,
        paths=[
            # git submodule object (folder) listed by 'git ls-files'
            "submodules/lens-test-project2",
            # git submodule contents
            "submodules/lens-test-project2/hello.py",
        ],
    ),
    # check that '.gitignore' isn't consulted (in an early draft of
    # Lensignore v2, '.gitignore' files were consulted in addition to
    # '.lensignore' files)
    Expect(
        selected=True,
        paths=[
            # pylens doesn't consult .gitignore files
            # (except for the one included in the .lensignore file)
            "src/gitignored.py",
            "src/gitignored-only-in-src-and-below.py",
            "src/gitignored-only-in-src.py",
        ],
    ),
]

# For our baseline commit, we use any commit in the middle of the git history
# such that some files changed after that commit but not all files.
GIT_BASELINE_COMMIT = "399245b4660c80530db13148e5aed3e6572ea351"
GIT_BASELINE_COMMIT_EXPECTATIONS = [
    Expect(
        selected=True,
        paths=[
            # Added in the first commit after the baseline commit
            ".gitignore",
            # Modified in a later commit
            "README.md",
        ],
    ),
    Expect(
        selected=False,
        paths=[
            # Added in by the baseline commit and not modified after that
            "hello.py",
            # Lensignored file
            "lensignored/hello.py",
        ],
    ),
]

NOVCS_PROJECT_EXPECTATIONS = [
    # common expectations for a novcs project (but not for a git project)
    Expect(
        selected=True,
        paths=[
            # regular file in what was a git submodule
            "submodules/lens-test-project2/hello.py",
            # we don't consult .gitignore files in novcs projects
            "src/gitignored.py",
            "src/gitignored-only-in-src-and-below.py",
            "src/gitignored-only-in-src.py",
        ],
    ),
    Expect(
        selected=False,
        paths=[
            "src/lensignored-via-include.py",
            # folder, not a regular file
            "submodules/lens-test-project2",
        ],
    ),
]

GIT_DEFAULT_LENSIGNORE_EXPECTATIONS = [
    Expect(
        selected=True,
        paths=[
            # sanity check
            "hello.py",
            # this is not ignored by the default lensignore patterns
            "lensignored/hello.py",
        ],
    ),
    Expect(
        selected=False,
        paths=[
            # .git is excluded by 'git ls-files'
            ".git/HEAD",
            # tests/ is excluded by the default lensignore patterns
            "tests/hello.py",
            # git submodules are ignored
            "submodules/lens-test-project2/hello.py",
        ],
    ),
]

NOVCS_DEFAULT_LENSIGNORE_EXPECTATIONS = [
    Expect(
        selected=True,
        paths=[
            # sanity check
            "hello.py",
            # this is not ignored by the default lensignore patterns
            "lensignored/hello.py",
            # git submodules are not ignored
            "submodules/lens-test-project2/hello.py",
            # this is not ignored by the default lensignore patterns
            "submodules/lens-test-project2/lensignored/hello.py",
        ],
    ),
    Expect(
        selected=False,
        paths=[
            # any .git file is excluded by the default lensignore patterns
            "submodules/lens-test-project2/.git",
            # tests/ is excluded by the default lensignore patterns
            "tests/hello.py",
            "submodules/lens-test-project2/tests/hello.py",
        ],
    ),
]

GIT_EMPTY_LENSIGNORE_EXPECTATIONS = [
    Expect(
        selected=True,
        paths=[
            "hello.py",
            "lensignored/hello.py",
            "tests/hello.py",
        ],
    ),
    Expect(
        selected=False,
        paths=[
            # always excluded by git
            ".git/HEAD",
            # submodule, excluded by git
            "submodules/lens-test-project2/hello.py",
        ],
    ),
]

NOVCS_EMPTY_LENSIGNORE_EXPECTATIONS = [
    Expect(
        selected=True,
        paths=[
            "hello.py",
            "lensignored/hello.py",
            "tests/hello.py",
            "submodules/lens-test-project2/hello.py",
            "submodules/lens-test-project2/lensignored/hello.py",
            "submodules/lens-test-project2/tests/hello.py",
        ],
    ),
    # pylens bugs
    Expect(
        selected=True,
        selected_by_pylens=False,
        paths=[
            "submodules/lens-test-project2/.git",
        ],
    ),
]


GIT_EXCLUDE_EXPECTATIONS = [
    Expect(
        selected=True,
        paths=[
            "hello.py",
        ],
    ),
    Expect(
        selected=False,
        paths=[
            "lensignored-at-root/ignoreme",
            "lensignored-at-root2/ignoreme",
        ],
    ),
    # pylens bugs
    Expect(
        selected=True,
        selected_by_pylens=False,
        paths=[
            "src/lensignored-at-root/scanme",
            "src/lensignored-at-root2/scanme",
        ],
    ),
]


NOVCS_EXCLUDE_EXPECTATIONS = [
    Expect(
        selected=True,
        paths=[
            "hello.py",
        ],
    ),
    Expect(
        selected=False,
        paths=[
            "lensignored-at-root/ignoreme",
            "lensignored-at-root2/ignoreme",
        ],
    ),
    # pylens bugs
    Expect(
        selected=True,
        selected_by_pylens=False,
        paths=[
            "src/lensignored-at-root/scanme",
            "src/lensignored-at-root2/scanme",
        ],
    ),
]


# In the --include tests, the meanings of 'ignoreme' and 'scanme' are
# reversed, sorry about the confusion.
GIT_INCLUDE_EXPECTATIONS = [
    Expect(
        selected=True,
        paths=[
            "lensignored-at-root/ignoreme",
            "lensignored-at-root2/ignoreme",
        ],
    ),
    Expect(
        selected=False,
        paths=[
            "hello.py",
        ],
    ),
    # pylens bugs
    Expect(
        selected=False,
        selected_by_pylens=True,
        paths=[
            "src/lensignored-at-root/scanme",
            "src/lensignored-at-root2/scanme",
        ],
    ),
]


# In the --include tests, the meanings of 'ignoreme' and 'scanme' are
# reversed, sorry about the confusion.
NOVCS_INCLUDE_EXPECTATIONS = [
    Expect(
        selected=True,
        paths=[
            "lensignored-at-root/ignoreme",
            "lensignored-at-root2/ignoreme",
        ],
    ),
    Expect(
        selected=False,
        paths=[
            "hello.py",
        ],
    ),
    # pylens bugs
    Expect(
        selected=False,
        selected_by_pylens=True,
        paths=[
            "src/lensignored-at-root/scanme",
            "src/lensignored-at-root2/scanme",
        ],
    ),
]

# Test --x-lensignore-filename
ALT_LENSIGNORE_EXPECTATIONS = [
    Expect(
        selected=True,
        paths=[
            "alt-lensignore",
        ],
    ),
    Expect(
        selected=False,
        # --x-lensignore-filename isn't supported by Lensignore v1
        selected_by_pylens=True,
        paths=[
            "hello.py",
        ],
    ),
]


@pytest.mark.kinda_slow
@pytest.mark.parametrize(
    # a list of extra lens CLI options and olens-specific options
    # TODO: remove olens_options since it's unused
    "config,options,olens_options,expectations",
    [
        (Config.GIT, [], [], COMMON_EXPECTATIONS + GIT_PROJECT_EXPECTATIONS),
        (
            Config.GIT_BASELINE_COMMIT,
            # nothing particular about this commit
            ["--baseline-commit", GIT_BASELINE_COMMIT],
            [],
            GIT_BASELINE_COMMIT_EXPECTATIONS,
        ),
        pytest.param(
            Config.NOVCS,
            [],
            [],
            COMMON_EXPECTATIONS + NOVCS_PROJECT_EXPECTATIONS,
            marks=skip_on_windows,  # Removing .git fails with perm error
        ),
        (
            Config.IGNOREGIT,
            ["--no-git-ignore"],
            [],
            COMMON_EXPECTATIONS + NOVCS_PROJECT_EXPECTATIONS,
        ),
        (
            Config.GIT_DEFAULT_LENSIGNORE,
            [],
            [],
            GIT_DEFAULT_LENSIGNORE_EXPECTATIONS,
        ),
        pytest.param(
            Config.NOVCS_DEFAULT_LENSIGNORE,
            [],
            [],
            NOVCS_DEFAULT_LENSIGNORE_EXPECTATIONS,
            marks=skip_on_windows,  # Removing .git fails with perm error
        ),
        (Config.GIT_EMPTY_LENSIGNORE, [], [], GIT_EMPTY_LENSIGNORE_EXPECTATIONS),
        pytest.param(
            Config.NOVCS_EMPTY_LENSIGNORE,
            [],
            [],
            NOVCS_EMPTY_LENSIGNORE_EXPECTATIONS,
            marks=skip_on_windows,  # Removing .git fails with perm error
        ),
        pytest.param(
            Config.GIT_EXCLUDE,
            [
                "--exclude",
                "/lensignored-at-root",
                "--exclude",
                "lensignored-at-root2/**",
            ],
            [],
            GIT_EXCLUDE_EXPECTATIONS,
            # When running the subprocess, the
            # `lensignored-at-root2/**` argument is escaped by the
            # subprocess to be wrapped in single quotes. This causes
            # the exclude pattern to fail. Running the equivalent
            # command run in the test on the CLI works correctly.
            marks=skip_on_windows,
        ),
        pytest.param(
            Config.NOVCS_EXCLUDE,
            [
                "--exclude",
                "/lensignored-at-root",
                "--exclude",
                "lensignored-at-root2/**",
            ],
            [],
            NOVCS_EXCLUDE_EXPECTATIONS,
            # When running the subprocess, the
            # `lensignored-at-root2/**` argument is escaped by the
            # subprocess to be wrapped in single quotes. This causes
            # the exclude pattern to fail. Running the equivalent
            # command run in the test on the CLI works correctly.
            marks=skip_on_windows,
        ),
        (
            Config.GIT_INCLUDE,
            [
                "--include",
                "/lensignored-at-root",
                "--include",
                "lensignored-at-root2/**",
            ],
            [],
            GIT_INCLUDE_EXPECTATIONS,
        ),
        (
            Config.NOVCS_INCLUDE,
            [
                "--include",
                "/lensignored-at-root",
                "--include",
                "lensignored-at-root2/**",
            ],
            [],
            NOVCS_INCLUDE_EXPECTATIONS,
        ),
        (
            Config.ALT_LENSIGNORE,
            [
                "--x-lensignore-filename",
                "alt-lensignore",
            ],
            [],
            ALT_LENSIGNORE_EXPECTATIONS,
        ),
    ],
    ids=[
        Config.GIT.value,
        Config.GIT_BASELINE_COMMIT.value,
        Config.NOVCS.value,
        Config.IGNOREGIT.value,
        Config.GIT_DEFAULT_LENSIGNORE.value,
        Config.NOVCS_DEFAULT_LENSIGNORE.value,
        Config.GIT_EMPTY_LENSIGNORE.value,
        Config.NOVCS_EMPTY_LENSIGNORE.value,
        Config.GIT_EXCLUDE.value,
        Config.NOVCS_EXCLUDE.value,
        Config.GIT_INCLUDE.value,
        Config.NOVCS_INCLUDE.value,
        Config.ALT_LENSIGNORE.value,
    ],
)
def test_project_target_selection(
    monkeypatch: pytest.MonkeyPatch,
    tmp_path: Path,
    run_lens: RunLens,
    config: Config,
    options: List[str],
    olens_options: List[str],
    expectations: List[Expect],
) -> None:
    project = PROJECT
    # Instead of copying or symlinking the git submodule that sits nicely
    # in our lens repo, we clone it as standalone repo to avoid problems
    # due to having the structure of a submodule but no parent git project.
    print(f"cd into {tmp_path}", file=sys.stderr)
    monkeypatch.chdir(tmp_path)
    print(f"clone {project.url}", file=sys.stderr)
    os.system(f"git clone {project.url} {project.name}")
    print(f"cd into {project.name}", file=sys.stderr)
    monkeypatch.chdir(Path(project.name))
    print(f"check out commit {project.commit}", file=sys.stderr)
    os.system(f"git checkout {project.commit}")
    print(f"check out submodules", file=sys.stderr)
    os.system(f"git submodule update --init --recursive")

    if (
        config is Config.NOVCS
        or config is Config.NOVCS_DEFAULT_LENSIGNORE
        or config is Config.NOVCS_EMPTY_LENSIGNORE
    ):
        print(f"remove .git to make this a no-VCS project", file=sys.stderr)
        shutil.rmtree(".git")

    if (
        config is Config.GIT_DEFAULT_LENSIGNORE
        or config is Config.NOVCS_DEFAULT_LENSIGNORE
        or config is Config.GIT_EMPTY_LENSIGNORE
        or config is Config.NOVCS_EMPTY_LENSIGNORE
        or config is Config.GIT_EXCLUDE
        or config is Config.NOVCS_EXCLUDE
        or config is Config.GIT_INCLUDE
        or config is Config.NOVCS_INCLUDE
    ):
        print(f"remove .lensignore files", file=sys.stderr)
        os.remove(".lensignore")
        os.remove("src/.lensignore")
        os.remove("submodules/lens-test-project2/.lensignore")
        if (
            config is Config.GIT_EMPTY_LENSIGNORE
            or config is Config.NOVCS_EMPTY_LENSIGNORE
            or config is Config.GIT_EXCLUDE
            or config is Config.NOVCS_EXCLUDE
            or config is Config.GIT_INCLUDE
            or config is Config.NOVCS_INCLUDE
        ):
            print(f"create an empty .lensignore", file=sys.stderr)
            open(".lensignore", "w").close()

    is_running_olens = True if os.environ.get("PYTEST_USE_OLENS") else False

    extra_options = options
    if is_running_olens:
        extra_options += olens_options

    # Call lens to list the target files and print them on stdout,
    # one per line.
    stdout, stderr = run_lens(
        # the '-e' and '--lang' options are to keep pylens happy because
        # it wants to load rules
        options=["--x-ls", "-e", "hello", "--lang", "python"] + extra_options,
        assume_targets_dir=False,
        target_name=".",
    )
    selected_targets: Set[str] = set(filter(lambda x: x, stdout.split("\n")))

    print(f"selected target paths:", file=sys.stderr)
    for path in sorted(list(selected_targets)):
        print(f"  {path}", file=sys.stderr)

    # Check the status of each file path we want to check.
    for expect in expectations:
        check_expectation(
            expect=expect,
            is_running_olens=is_running_olens,
            config=config,
            selected_targets=selected_targets,
        )
