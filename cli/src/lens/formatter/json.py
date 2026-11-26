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
from typing import Any
from typing import Iterable
from typing import Mapping
from typing import Sequence

import lens.formatter.base as base
import lens.rpc_call
import lens.lens_interfaces.lens_output_v1 as out
from lens.error import LensError
from lens.rule import Rule
from lens.rule_match import RuleMatch
from lens.verbose_logging import getLogger

logger = getLogger(__name__)


class JsonFormatter(base.BaseFormatter):
    """Filter out some fields depending on the context and format the result
    into a JSON string.
    """

    def format(
        self,
        rules: Iterable[Rule],
        rule_matches: Iterable[RuleMatch],
        lens_structured_errors: Sequence[LensError],
        cli_output_extra: out.CliOutputExtra,
        extra: Mapping[str, Any],
        ctx: out.FormatContext,
    ) -> str:
        output = base.to_CliOutput(
            rule_matches,
            lens_structured_errors,
            cli_output_extra,
            max_match_context_size=extra.get("max_match_context_size", 0),
        )
        # Filter out some fields depending on context ctx!
        # This filtering is implemented on the OCaml side.
        return lens.rpc_call.format(out.OutputFormat(out.Json()), ctx, output)
