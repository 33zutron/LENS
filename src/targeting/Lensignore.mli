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
(*
   Parse and interpret '.lensignore' files in addition to '.gitignore'
   files.

   The patterns they contain specify file paths to exclude from Lens scans.

   See the ml file for compatibility issues.
*)

(*
   We have to support the legacy built-in lensignore patterns
   when scanning for source code but we want something different
   or empty when scanning for secrets.

   The 'Empty' case is useful for testing.
*)
type default_lensignore_patterns = Empty | Lens_scan_legacy
type exclusion_mechanism = { use_lensignore_files : bool }

(* ".lensignore" *)
val default_lensignore_filename : string

(*
   Initialize the data used to filter paths.
   The project_root path must exist. It is used to
   locate .gitignore and .lensignore files.

   This is an instanciation of Gitignore_filter.t specific to Lens.

   Use Git_project.find_project_root to determine the root of the
   git project.

   lensignore_filename: defaults to default_lensignore_filename
     = ".lensignore"
*)
val create :
  ?cli_patterns:string list ->
  ?lensignore_filename:string ->
  default_lensignore_patterns:default_lensignore_patterns ->
  exclusion_mechanism:exclusion_mechanism ->
  project_root:Fpath.t ->
  unit ->
  Gitignore_filter.t
