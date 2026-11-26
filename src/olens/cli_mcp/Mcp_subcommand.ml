(*
   Copyright (c) 2022-2025 Lens Inc.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public License
   version 2.1 as published by the Free Software Foundation.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the file
   LICENSE for more details.
*)
(*****************************************************************************)
(* Prelude *)
(*****************************************************************************)
(*
   Parse a lens-mcp command, execute it and exit.

*)

(*****************************************************************************)
(* Types *)
(*****************************************************************************)
let hook_run_mcp : (Mcp_CLI.conf -> unit) option Hook.t = Hook.create None

(*****************************************************************************)
(* Main logic *)
(*****************************************************************************)

(* All the business logic after command-line parsing. Return the desired
   exit code. *)
let run_conf (conf : Mcp_CLI.conf) : Exit_code.t =
  CLI_common.with_logging ~color:Auto ~level:conf.common.logging_level
    (fun () ->
      Logs.debug (fun m -> m "Starting lens-mcp");
      (* let's go! *)
      match Hook.get hook_run_mcp with
      | Some run_mcp ->
          run_mcp conf;
          Exit_code.ok ~__LOC__
      | None ->
          Logs.err (fun m ->
              m
                "MCP subcommand requires Pro Engine--make sure you are using \
                 the proprietary lens binary.");
          Exit_code.fatal ~__LOC__)

(*****************************************************************************)
(* Entry point *)
(*****************************************************************************)

let main (argv : string array) : Exit_code.t =
  let conf = Mcp_CLI.parse_argv argv in
  run_conf conf
