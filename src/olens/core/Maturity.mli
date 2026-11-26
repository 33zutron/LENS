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
(* This module is used mostly to decide between pylens and olens.
 * It could be used for different things later.
 *)

type t =
  (* mix of pylens and olens, depending on CLI arguments (see CLI.ml) *)
  | Default
  (* for forcing pylens *)
  | Legacy
  (* for forcing olens *)
  | Experimental
  (* Leaving on the edge, using olens with olens-only features enabled *)
  | Develop
[@@deriving show]

(* --experimental/--legacy/--develop CLI processing *)
val o_maturity : t Cmdliner.Term.t
