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
(*
   'lens install-lens-pro' command-line parsing.
*)

(*
   The result of parsing a 'lens install-lens-pro' command.
*)

type conf = {
  common : CLI_common.conf;
  custom_binary : string option;
  (* not used by the OCaml implementation: parsed only so the flag can be
   * passed through to pylens (see Pylens.Fallback in
   * Install_lens_pro_subcommand.ml)
   *)
  metrics : Metrics_.config;
}
[@@deriving show]

(*
   Usage: parse_argv [| "lens-install-lens-pro"; <args> |]

   Turn argv into a conf structure.
*)
val parse_argv : string array -> conf
