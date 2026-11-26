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
type t = {
  (* targets skipped because of file targeting semantic *)
  ignored : Lens_output_v1_t.skipped_target list;
  size : Lens_output_v1_t.skipped_target list;
  include_ : Lens_output_v1_t.skipped_target list;
  exclude : Lens_output_v1_t.skipped_target list;
  always : Lens_output_v1_t.skipped_target list;
  other : Lens_output_v1_t.skipped_target list;
  (* targets skipped because there was parsing/matching
   * errors while running the engine on it (see errors_to_skipped())
   *)
  errors : Lens_output_v1_t.skipped_target list;
}

val group : Lens_output_v1_t.skipped_target list -> t

(* internal also used in Scan_subcommand.ml *)
val errors_to_skipped :
  Lens_output_v1_t.core_error list -> Lens_output_v1_t.skipped_target list
