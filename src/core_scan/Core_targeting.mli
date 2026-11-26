(*
   Copyright (c) 2025 Lens Inc.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public License
   version 2.1 as published by the Free Software Foundation.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the file
   LICENSE for more details.
*)
(*
   Target discovery can now be done in lens-core using scanning roots
   passed by pylens.

   This module takes care of splitting targets by language as requested
   by the legacy lens-core input interface.
*)

(* reused for Git_remote.ml in pro *)
val split_jobs_by_language :
  Find_targets.conf -> Rule.t list -> Fppath.t list -> Lang_job.t list

val targets_and_rules_of_lang_jobs :
  Lang_job.t list -> Target.t list * Rule.t list

(* Helper used in Test_subcommand.ml and Core_scan.ml where we now
   discover targets in lens-core rather than in pylens.
   Used also by `lens show dump-targets <dir> <rules_config>`
*)
val targets_for_files_and_rules : Fppath.t list -> Rule.t list -> Target.t list
