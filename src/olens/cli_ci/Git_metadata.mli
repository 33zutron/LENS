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
(* Gather metadata from local filesystem (we expect, at least, a Git
    repository) of from lens-specific environment variables
*)

type env = {
  _LENS_REPO_NAME : string option;
  _LENS_REPO_DISPLAY_NAME : string option;
  _LENS_REPO_URL : Uri.t option;
  _LENS_COMMIT : Digestif.SHA1.t option;
  _LENS_JOB_URL : Uri.t option;
  _LENS_PR_ID : string option;
  _LENS_PR_TITLE : string option;
  _LENS_BRANCH : string option;
  _LENS_PROJECT_ID : string option;
}

(* Extract the environment variable via Cmdliner.
 * Why using cmdliner? Why not simply access them with Sys.getenv_opt?
 * The advantage of cmdliner is that we can document those variables
 * and the env constant below can be combined in Ci_CLI.ml so those
 * variables can be part of the 'lens ci' man page!!
 *)
val env : env Cmdliner.Term.t

class meta :
  scan_environment:string ->
  baseline_ref:Digestif.SHA1.t option ->
  env ->
object
  method project_metadata : Lens_output_v1_t.project_metadata

  (* to be overriden in the children *)
  method branch : string option
  method ci_job_url : Uri.t option
  method commit_sha : Digestif.SHA1.t option
  method event_name : string
  method is_full_scan : bool
  method pr_id : string option
  method pr_title : string option
  method repo_name : string
  method repo_display_name : string
  method repo_url : Uri.t option
  method merge_base_ref : Digestif.SHA1.t option
  method project_id : string option
end
