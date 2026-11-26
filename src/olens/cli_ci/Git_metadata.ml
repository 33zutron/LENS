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
open Common
module Arg = Cmdliner.Arg
module Term = Cmdliner.Term
module XCmd = Cmdliner.Cmd

(*****************************************************************************)
(* Prelude *)
(*****************************************************************************)
(* Extract metadata from the git repo, or from LENS_XXX environment
 * variables if set.
 *
 * TODO? rename to Git_and_lens_metadata.ml ?
 *)

(*****************************************************************************)
(* Types *)
(*****************************************************************************)

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

(*****************************************************************************)
(* Cmdliner *)
(*****************************************************************************)

(* TODO: right now we have also to use CLI flags like "lens-repo-name"
 * otherwise cmdliner raise an exn about empty info.
 *)
let env : env Term.t =
  let lens_repo_name =
    let doc = "The name of the Git repository." in
    let env = XCmd.Env.info "LENS_REPO_NAME" in
    Arg.(
      value & opt (some string) None & info [ "lens-repo-name" ] ~env ~doc)
  in
  let lens_repo_display_name =
    let doc =
      "The name the repository should be displayed as for this scan. Setting \
       it allows users to scan individual repos in one monorepo separately."
    in
    let env = XCmd.Env.info "LENS_REPO_DISPLAY_NAME" in
    Arg.(
      value
      & opt (some string) None
      & info [ "lens-repo-display-name" ] ~env ~doc)
  in
  let lens_repo_url =
    let doc = "The URL of the Git repository." in
    let env = XCmd.Env.info "LENS_REPO_URL" in
    Arg.(
      value
      & opt (some Cmdliner_.uri) None
      & info [ "lens-repo-url" ] ~env ~doc)
  in
  let lens_commit =
    let doc = "The commit of the Git repository." in
    let env = XCmd.Env.info "LENS_COMMIT" in
    Arg.(
      value
      & opt (some Cmdliner_.sha1) None
      & info [ "lens-commit" ] ~env ~doc)
  in
  let lens_job_url =
    let doc = "The job URL." in
    let env = XCmd.Env.info "LENS_JOB_URL" in
    Arg.(
      value
      & opt (some Cmdliner_.uri) None
      & info [ "lens-job-url" ] ~env ~doc)
  in
  let lens_pr_id =
    let doc = "The PR/MR ID." in
    let env = XCmd.Env.info "LENS_PR_ID" in
    Arg.(value & opt (some string) None & info [ "lens-pr-id" ] ~env ~doc)
  in
  let lens_pr_title =
    let doc = "The PR/MR title." in
    let env = XCmd.Env.info "LENS_PR_TITLE" in
    Arg.(value & opt (some string) None & info [ "lens-pr-title" ] ~env ~doc)
  in
  let lens_branch =
    let doc = "The Git branch." in
    let env = XCmd.Env.info "LENS_BRANCH" in
    Arg.(value & opt (some string) None & info [ "lens-branch" ] ~env ~doc)
  in
  let lens_project_id =
    let doc =
      "The project ID that this scan sends findings to. Must not be set at the \
       same time as LENS_REPO_DISPLAY_NAME."
    in
    let env = XCmd.Env.info "LENS_PROJECT_ID" in
    Arg.(
      value & opt (some string) None & info [ "lens-project-id" ] ~env ~doc)
  in
  let run _LENS_REPO_NAME _LENS_REPO_DISPLAY_NAME _LENS_REPO_URL
      _LENS_COMMIT _LENS_JOB_URL _LENS_PR_ID _LENS_PR_TITLE
      _LENS_BRANCH _LENS_PROJECT_ID =
    {
      _LENS_REPO_NAME;
      _LENS_REPO_DISPLAY_NAME;
      _LENS_REPO_URL;
      _LENS_COMMIT;
      _LENS_JOB_URL;
      _LENS_PR_ID;
      _LENS_PR_TITLE;
      _LENS_BRANCH;
      _LENS_PROJECT_ID;
    }
  in
  Term.(
    const run $ lens_repo_name $ lens_repo_display_name $ lens_repo_url
    $ lens_commit $ lens_job_url $ lens_pr_id $ lens_pr_title
    $ lens_branch $ lens_project_id)

(*****************************************************************************)
(* Entry point *)
(*****************************************************************************)

class meta ~scan_environment ~(baseline_ref : Digestif.SHA1.t option) env =
  object (self)
    method project_metadata : Project_metadata.t =
      let commit_title : string =
        Git_wrapper.command_exn [ "show"; "-s"; "--format=%B" ]
      in
      let commit_author_email_str : string =
        Git_wrapper.command_exn [ "show"; "-s"; "--format=%ae" ]
      in
      (* old: |> Emile.of_string |> Result.get_ok
       * but github generates emails like
       * 106279034+lens-ci[bot]@users.noreply.github.com
       * which are not valid for Emile so simpler to use
       * the raw string as in pylens
       *)
      let commit_author_name : string =
        Git_wrapper.command_exn [ "show"; "-s"; "--format=%an" ]
      in
      (* Returns strict ISO 8601 time as str of head commit *)
      let commit_timestamp : Timedesc.Timestamp.t =
        Git_wrapper.command_exn [ "show"; "-s"; "--format=%cI" ]
        |> Timedesc.Timestamp.of_iso8601 |> Result.get_ok
      in
      {
        (* REQUIRED for lens backend *)
        repository = self#repo_name;
        (* OPTIONAL for lens backend *)
        repo_url = self#repo_url;
        repo_display_name = Some self#repo_display_name;
        branch = self#branch;
        ci_job_url = self#ci_job_url;
        commit = self#commit_sha;
        commit_author_email = Some commit_author_email_str;
        commit_author_name = Some commit_author_name;
        commit_author_username = None;
        commit_author_image_url = None;
        commit_title = Some commit_title;
        commit_timestamp = Some commit_timestamp;
        on = self#event_name;
        pull_request_author_username = None;
        pull_request_author_image_url = None;
        pull_request_id = self#pr_id;
        pull_request_title = self#pr_title;
        scan_environment;
        base_branch_head_commit = None;
        is_full_scan = self#is_full_scan;
        repo_id = None;
        org_id = None;
        (* TODO ugly: gitlab stuff, should maybe split
         * lens_output_v1.metadata and use inherit
         *)
        base_sha = None;
        start_sha = None;
        is_sca_scan = None;
        is_code_scan = None;
        is_secrets_scan = None;
        project_id = self#project_id;
      }

    (* to be overriden in children *)
    method repo_name =
      match env._LENS_REPO_NAME with
      | Some repo_name -> repo_name
      | None ->
          let str =
            Git_wrapper.command_exn [ "rev-parse"; "--show-toplevel" ]
          in
          Printf.sprintf "local_scan/%s" (Fpath.basename (Fpath.v str))

    method repo_display_name =
      match env._LENS_REPO_DISPLAY_NAME with
      | Some repo_display_name -> repo_display_name
      | None -> self#repo_name

    method repo_url =
      match env._LENS_REPO_URL with
      | Some repo_url -> Some repo_url
      | None -> (
          let cmd = (Cmd.Name "git", [ "remote"; "get-url"; "origin" ]) in
          match UCmd.string_of_run ~trim:true cmd with
          | Ok (str, _status) ->
              Project_metadata.get_url_from_sstp_url (Some str)
          | Error (`Msg _err) ->
              Logs.warn (fun m ->
                  m
                    "Unable to infer repo_url. Set LENS_REPO_URL \
                     environment variable or run in a valid git project with \
                     remote origin defined.");
              None)

    method branch =
      match env._LENS_BRANCH with
      | Some branch -> Some branch
      | None -> (
          let cmd = (Cmd.Name "git", [ "rev-parse"; "--abbrev-ref"; "HEAD" ]) in
          match UCmd.string_of_run ~trim:true cmd with
          | Ok (branch, (_, `Exited 0)) -> Some branch
          | Ok _
          | Error (`Msg _) ->
              None)

    method ci_job_url = env._LENS_JOB_URL

    method commit_sha =
      match env._LENS_COMMIT with
      | Some sha1 -> Some sha1
      | None -> (
          let cmd = (Cmd.Name "git", [ "rev-parse"; "HEAD" ]) in
          match UCmd.string_of_run ~trim:true cmd with
          | Ok (str, (_, `Exited 0)) -> Digestif.SHA1.of_hex_opt str
          | Ok _
          | Error (`Msg _) ->
              None)

    method event_name =
      match self#pr_id with
      | Some _ -> "pull_request"
      | None -> "unknown"

    method pr_id = env._LENS_PR_ID
    method pr_title = env._LENS_PR_TITLE
    method is_full_scan = self#merge_base_ref =*= None

    (* TODO? get rid of? use directly baseline_ref in is_full_scan? *)
    method merge_base_ref = baseline_ref

    method project_id =
      match (env._LENS_REPO_DISPLAY_NAME, env._LENS_PROJECT_ID) with
      | Some _repo_display_name, Some _project_id ->
          Logs.app (fun m ->
              m
                "The environment variables LENS_PROJECT_ID and \
                 LENS_REPO_DISPLAY_NAME cannot both be set at the same \
                 time.");
          Error.exit_code_exn (Exit_code.fatal ~__LOC__)
      | _, project_id -> project_id
  end
