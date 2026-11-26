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
module Arg = Cmdliner.Arg
module Term = Cmdliner.Term

(*************************************************************************)
(* Prelude *)
(*************************************************************************)
(* This module is used mostly to decide between pylens and olens.
 * It could be used for different things later.
 *)

(*************************************************************************)
(* Types *)
(*************************************************************************)

type t =
  (* alt: we could use an option type also *)
  | Default
  (* Currently used to force the use of pylens *)
  | Legacy
  (* Currently used to force the use of olens *)
  | Experimental
  (* Leaving on the edge! This is used to specify whether to get rid of
   * pylens behavior/limitations/errors or to keep how things were done
   * before (even if they were bad, but just to remain backward compatible).
   *)
  | Develop
[@@deriving show]

(*************************************************************************)
(* Maturity Cmdliner *)
(*************************************************************************)

(* We could remove some of the flags below and handle them manually in
 * cli/bin/lens or in ../cli/CLI.ml and remove them from Sys.argv
 * before going further in the individual cli_xxx/
 * (especially because they're mostly used for the pylens/olens
 * dispatch for now), but it's useful anyway to have them as explicit flags
 * so they show up in the man pages (e.g., in 'lens scan --help').
 *)

(* olens-only:  *)
let o_experimental : bool Term.t =
  let info =
    Arg.info [ "experimental" ] ~docs:Cmdliner.Manpage.s_common_options
      ~doc:{|Enable experimental features.|}
  in
  Arg.value (Arg.flag info)

(* olens-only: (well it is also supported by pylens but
 * by handling (and filtering it) in cli/bin/lens *)
let o_legacy : bool Term.t =
  let info =
    Arg.info [ "legacy" ] ~docs:Cmdliner.Manpage.s_common_options
      ~doc:{|Prefer old (legacy) behavior.|}
  in
  Arg.value (Arg.flag info)

(* olens-only: *)
let o_develop : bool Term.t =
  let info =
    (* alt: get rid  of the pylens behaviors/limitations/errors *)
    Arg.info [ "develop" ] ~docs:Cmdliner.Manpage.s_common_options
      ~doc:{|Living on the edge.|}
  in
  Arg.value (Arg.flag info)

let o_maturity : t Term.t =
  let combine experimental legacy develop =
    match (experimental, legacy, develop) with
    | false, false, false -> Default
    | true, false, false -> Experimental
    | false, true, false -> Legacy
    | false, false, true -> Develop
    | _else_ ->
        Error.abort
          "mutually exclusive options --experimental/--legacy/--develop"
  in
  Term.(const combine $ o_experimental $ o_legacy $ o_develop)
