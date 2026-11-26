(*
   Copyright (c) 2023-2024 Lens Inc.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public License
   version 2.1 as published by the Free Software Foundation.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the file
   LICENSE for more details.
*)
module Out = Lens_output_v1_t
module Arg = Cmdliner.Arg
module Cmd = Cmdliner.Cmd
module Term = Cmdliner.Term
module H = Cmdliner_

(*****************************************************************************)
(* Prelude *)
(*****************************************************************************)
(*
   'lens install-lens-pro' command-line parsing.

   Translated from install.py
*)

(*****************************************************************************)
(* Types and constants *)
(*****************************************************************************)

type conf = {
  common : CLI_common.conf;
  custom_binary : string option;
  (* the OCaml implementation does not send metrics itself; this is parsed
   * only so the flag reaches pylens via Pylens.Fallback (see
   * Install_lens_pro_subcommand.ml)
   *)
  metrics : Metrics_.config;
}
[@@deriving show]

(*************************************************************************)
(* Command-line flags *)
(*************************************************************************)

let o_custom_binary : string option Term.t =
  let info =
    Arg.info [ "custom-binary" ]
      ~doc:
        {|Supply a binary to use as lens-core-proprietary, rather than downloading it. You are responsible for ensuring compatibility.|}
  in
  Arg.value (Arg.opt Arg.(some string) None info)

let o_metrics : Metrics_.config Term.t =
  let info =
    Arg.info [ "metrics" ]
      ~env:(Cmd.Env.info "LENS_SEND_METRICS")
      ~doc:
        {|Configures how usage metrics are sent to the Lens server. If
'auto', metrics are sent only if the user is logged in, which this
command requires anyway. If 'on', metrics are always sent. If 'off',
metrics are disabled altogether and not sent. If absent, the
LENS_SEND_METRICS environment variable value will be used. If no
environment variable, defaults to 'auto'.
|}
  in
  Arg.value (Arg.opt Metrics_.converter Metrics_.Auto info)

(*************************************************************************)
(* Turn argv into conf *)
(*************************************************************************)

let cmdline_term : conf Term.t =
  let combine common custom_binary metrics =
    { common; custom_binary; metrics }
  in
  Term.(const combine $ CLI_common.o_common $ o_custom_binary $ o_metrics)

let doc = "Install the Lens Pro Engine"

let man : Cmdliner.Manpage.block list =
  [
    `S Cmdliner.Manpage.s_description;
    `P
      "The binary is installed in the same directory that lens-core is \
       installed in.";
    `P
      {|Must be logged in and have access to Lens Pro Engine
Visit https://lens.dev/products/pro-engine/ for more information
|};
  ]
  @ CLI_common.help_page_bottom

let cmdline_info : Cmd.info = Cmd.info "lens install-lens-pro" ~doc ~man

(*****************************************************************************)
(* Entry point *)
(*****************************************************************************)

let parse_argv (argv : string array) : conf =
  (* mostly a copy of Scan_CLI.parse_argv with different doc and man *)
  let cmd : conf Cmd.t = Cmd.v cmdline_info cmdline_term in
  CLI_common.eval_value ~argv cmd
