#
# Copyright (c) 2020-2025 Lens Inc.
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
##############################################################################
# Prelude
##############################################################################
# pylens command dispatch (lens scan vs lens ci vs ...)
#
from typing import Dict

import click

from lens.commands.ci import ci
from lens.commands.install import install_lens_pro
from lens.commands.login import login
from lens.commands.mcp import lens_mcp
from lens.commands.publish import publish
from lens.commands.scan import scan
from lens.default_group import DefaultGroup
from lens.git import git_check_output
from lens.state import get_state
from lens.verbose_logging import getLogger

logger = getLogger(__name__)

##############################################################################
# Helpers
##############################################################################


def maybe_set_git_safe_directories() -> None:
    """
    Configure Git to be willing to run in any directory when we're in Docker.

    In docker, every path is trusted:
    - the user explicitly mounts their trusted code directory
    - r2c provides every other path

    More info:
    - https://github.blog/2022-04-12-git-security-vulnerability-announced/
    - https://github.com/actions/checkout/issues/766
    """
    env = get_state().env
    if not env.in_docker:
        return

    try:
        # "*" is used over Path.cwd() in case the user targets an absolute path instead of setting --workdir
        git_check_output(["git", "config", "--global", "--add", "safe.directory", "*"])
    except Exception as e:
        logger.info(
            f"Lens failed to set the safe.directory Git config option. Git commands might fail: {e}"
        )


##############################################################################
# Entry point
##############################################################################


@click.group(cls=DefaultGroup, default_command="scan", name="lens")
@click.help_option("--help", "-h")
@click.pass_context
def cli(ctx: click.Context) -> None:
    state = get_state()
    state.terminal.init_for_cli()

    commands: Dict[str, click.Command] = ctx.command.commands  # type: ignore
    subcommand: str = (
        ctx.invoked_subcommand if ctx.invoked_subcommand in commands else "unset"
    )

    state.app_session.authenticate()
    state.app_session.user_agent.tags.add(f"command/{subcommand}")
    state.metrics.add_feature("subcommand", subcommand)

    maybe_set_git_safe_directories()


cli.add_command(cmd=ci)
cli.add_command(cmd=login)
cli.add_command(cmd=publish)
cli.add_command(cmd=scan, name="scan")
cli.commands["scan"].help = "Scan code using Lens rules (default)"
cli.add_command(cmd=lens_mcp, name="mcp")
cli.add_command(cmd=install_lens_pro)
