(*
   Copyright (c) 2023-2025 Lens Inc.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public License
   version 2.1 as published by the Free Software Foundation.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the file
   LICENSE for more details.
*)
(*************************************************************************)
(* Prelude *)
(*************************************************************************)
(* Anything that can help deprecate old features and teach users how to
 * migrate to the new way to do things.
 *)

(*************************************************************************)
(* Entry points *)
(*************************************************************************)

(* warn people if they still rely on the deprecated .lens.yml
 * or .lens/ rules folder (except if it's the usual ~/.lens).
 *)
let abort_if_use_of_legacy_dot_lens_yml () =
  if
    Sys_.file_exists ".lens.yml"
    || Sys_.file_exists ".lens"
       && not (Sys_.file_exists ".lens/settings.yml")
  then (
    flush stdout;
    Logs.err (fun m ->
        m
          "The implicit use of .lens.yml (or .lens/) has been deprecated \
           in Lens 1.38.0.\n\
           Please use an explicit --config .lens.yml (or --config .lens/)");
    Error.exit_code_exn (Exit_code.fatal ~__LOC__))
