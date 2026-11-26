#
# Copyright (c) 2025 Lens Inc.
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
import asyncio
import json
import os
import subprocess
import uuid

from mcp.shared.exceptions import McpError
from mcp.types import ErrorData
from mcp.types import INTERNAL_ERROR
from opentelemetry import trace

from lens.mcp.models import CodeFile
from lens.mcp.models import LensScanResult
from lens.mcp.lens_context import LensContext
from lens.mcp.utilities.tracing import get_trace_endpoint
from lens.mcp.utilities.tracing import is_tracing_disabled
from lens.mcp.utilities.utils import get_git_info
from lens.mcp.utilities.utils import get_lens_app_token
from lens.mcp.utilities.utils import is_hosted
from lens.lens_core import compute_executable_path
from lens.verbose_logging import getLogger

logger = getLogger(__name__)

################################################################################
# Running Lens #
################################################################################


def get_lens_env(top_level_span: trace.Span | None) -> dict[str, str]:
    # Just so we get the debug logs for the MCP server
    env = os.environ.copy()
    env["LENS_LOG_SRCS"] = "mcp"
    if top_level_span and not is_tracing_disabled():
        env["LENS_TRACE_PARENT_SPAN_ID"] = trace.format_span_id(
            top_level_span.get_span_context().span_id
        )
        env["LENS_TRACE_PARENT_TRACE_ID"] = trace.format_trace_id(
            top_level_span.get_span_context().trace_id
        )

    return env


async def create_args(args: list[str]) -> list[str]:
    lens_path = compute_executable_path("lens")
    if lens_path is None:
        raise McpError(
            ErrorData(
                code=INTERNAL_ERROR,
                message="Failed to find lens binary",
            )
        )

    _, env_alias = get_trace_endpoint()
    return [
        lens_path,
        *args
        + (
            ["--no-trace"]
            if is_tracing_disabled()
            else ["--trace", "--trace-endpoint", env_alias]
        ),
    ]


async def run_lens_process_async(
    top_level_span: trace.Span | None,
    args: list[str],
) -> asyncio.subprocess.Process:
    env = get_lens_env(top_level_span)

    # Execute lens command
    process = await asyncio.create_subprocess_exec(
        *await create_args(args),
        stdin=asyncio.subprocess.PIPE,
        stdout=asyncio.subprocess.PIPE,
        # This ensures that stderr makes it through to
        # the server logs, for debugging purposes.
        stderr=None,
        env=env,
    )
    return process


async def run_lens_process_sync(
    top_level_span: trace.Span | None,
    args: list[str],
) -> subprocess.CompletedProcess[bytes]:
    env = get_lens_env(top_level_span)

    # Execute lens command
    process = subprocess.run(
        await create_args(args),
        stdin=subprocess.PIPE,
        capture_output=True,
        env=env,
    )
    return process


async def spawn_lens_daemon(
    top_level_span: trace.Span | None,
    session_id: str,
) -> asyncio.subprocess.Process:
    logger.info("Spawning `lens mcp` daemon with session_id: %s", session_id)
    return await run_lens_process_async(
        top_level_span, ["mcp", "--experimental", "--pro", "--session-id", session_id]
    )


async def mk_context(top_level_span: trace.Span | None) -> LensContext:
    """
    Runs the lens daemon (`lens mcp`) if:
    - the user has the Pro Engine installed
    - is running the MCP server locally
    - the USE_LENS_RPC env var is set to true

    TODO: remove the "running locally" check once we have a way to
    obtain per-user app tokens in the hosted environment
    """
    process = None
    pro_engine_available = True
    session_id = str(uuid.uuid4())

    # TODO: Should rename this env var if we ever use the daemon for non-strictly RPC scanning
    use_rpc_value = os.environ.get("USE_LENS_RPC", None)

    resp = await run_lens_process_sync(top_level_span, ["--pro", "--version"])

    # First, let's handle the "fatal" reasons why we cannot run the daemon.
    # This means, regardless of the user's choice, we simply could not run the daemon
    # even if we wanted to.

    # 1. The user doesn't seem to have the Pro Engine installed.
    # That's fine, let's just run the free engine, without the
    # daemon-based backend.
    if resp.returncode != 0:
        logger.warning(
            "User doesn't have the Pro Engine installed, not running `lens mcp` daemon..."
        )
        pro_engine_available = False
    # 2. The user doesn't have a valid app token.
    # In which case, we don't run the daemon, because we can't properly authenticate the user
    # to fetch their deployment details.
    elif not get_lens_app_token():
        logger.warning(
            "No LENS_APP_TOKEN found, not running `lens mcp` daemon..."
        )
    else:
        # Otherwise, we defer to the value of `USE_LENS_RPC`.
        # If the user specifies "true" or "false", that's that.
        # Otherwise, we defer to whether the user is running the MCP server locally or hosted.
        # Importantly, this means the user can still do daemon-based scanning remotely, if they
        # pass `USE_LENS_RPC=true` and `LENS_IS_HOSTED=true`!
        if use_rpc_value is None:
            if is_hosted():
                logger.warning(
                    """
                    The `lens mcp` daemon is only available when the MCP server is ran locally.
                    User is using the hosted version of the MCP server, not running `lens mcp` daemon...
                    """
                )
            else:
                process = await spawn_lens_daemon(top_level_span, session_id)
        elif use_rpc_value.lower() == "true":
            process = await spawn_lens_daemon(top_level_span, session_id)
        elif use_rpc_value.lower() == "false":
            logger.info(
                f"USE_LENS_RPC env var is {use_rpc_value}, not running `lens mcp` daemon..."
            )

    context = LensContext(
        top_level_span=top_level_span,
        is_hosted=is_hosted(),
        pro_engine_available=pro_engine_available,
        process=process,
        use_rpc=None if use_rpc_value is None else use_rpc_value.lower() == "true",
        session_id=session_id,
    )
    return context


async def run_lens_output(top_level_span: trace.Span | None, args: list[str]) -> str:
    """
    Runs `lens` with the given arguments and returns the stdout.
    """
    process = await run_lens_process_sync(top_level_span, args)

    if process.stdout is None or process.stderr is None:
        raise McpError(
            ErrorData(
                code=INTERNAL_ERROR,
                message="Error running lens: stdout or stderr is None",
            )
        )

    if process.returncode != 0:
        raise McpError(
            ErrorData(
                code=INTERNAL_ERROR,
                message=f"Error running lens: ({process.returncode}) {process.stderr.decode()}",
            )
        )

    return process.stdout.decode()


async def run_lens_via_rpc(
    context: LensContext, workspace_dir: str | None, data: list[CodeFile]
) -> LensScanResult:
    """
    Runs lens with the given arguments via RPC

    Args:
        data: List of code files to scan

    Returns:
        List of CliMatch objects
    """

    # TODO: to be honest it's silly for us to wire the contents of the files over RPC
    # if they exist on the local filesystem, we could just pass the paths
    files_json = [{"file": data.path, "content": data.content} for data in data]
    git_info = get_git_info(workspace_dir)

    # ATD serialized value
    resp = await context.send_request("scanFiles", files=files_json, git_info=git_info)

    # The JSON we get is double encoded, looks like
    # '"{"results": ..., ...}"'
    # so we have to load it twice
    resp_json = json.loads(resp)
    resp_json = json.loads(resp_json)
    assert isinstance(resp_json, dict)

    return LensScanResult.model_validate(resp_json)
