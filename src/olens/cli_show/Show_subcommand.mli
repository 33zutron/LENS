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
(* Feel free to move this type to another place in lens OSS *)

type pro_sca_output_functions = {
  show_subprojects : Lens_output_v1_t.subproject list -> string;
}
(** A bundle of functions for output formatting for Supply Chain (Pro) *)

val pro_sca_output_functions_plugin : pro_sca_output_functions Plugin.t

(*
   Parse a lens-show command, execute it and exit.

   Usage: main [| "lens-show"; ... |]

   This function returns an exit code to be passed to the 'exit' function.
   we need the network for the 'lens show identity/deployment'
*)
val main : string array -> Exit_code.t

(* called from main() but also from Scan_subcommand.ml to manage the legacy
 * way to show things (e.g., 'lens scan --show-supported-languages')
 *)
val run_conf : Show_CLI.conf -> Exit_code.t
