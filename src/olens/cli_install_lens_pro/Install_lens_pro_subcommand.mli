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
(* We timeout after 10s if the install fails.
 * We run lens -pro_version as part of the install process.
 *)
(*
   Parse a lens-install-lens-pro command, execute it and exit.

   Usage: main [| "lens-lens-pro"; ... |]

   This function returns an exit code to be passed to the 'exit' function.
*)
val main : string array -> Exit_code.t

(* internal *)
val run_conf : Install_lens_pro_CLI.conf -> Exit_code.t
