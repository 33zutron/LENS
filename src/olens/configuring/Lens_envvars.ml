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
open Fpath_.Operators

(*****************************************************************************)
(* Prelude *)
(*****************************************************************************)
(*
   Typed access to Lens environment variables (e.g., LENS_IN_DOCKER).

   Translated from env.py.

   There are other Lens environment variables which are not mentioned
   in this file because their value is accessed by Cmdliner
   in Scan_CLI.ml (LENS_BASELINE_COMMIT, LENS_SEND_METRICS,
   LENS_TIMEOUT, and LENS_RULES).

   TODO: Maybe we should make Env.v a lazy value. If we get an
   exn for any reason during the init, it will be raised even before
   main() is called, which leaves no room for error handling and
   better error messaging.

   TODO: switch to cmdliner, like we did in Git_metadata.mli so
   those variables can be combined in xxx_CLI.ml and be part
   of the man pages of those commands!
*)

(*****************************************************************************)
(* Constants *)
(*****************************************************************************)

let settings_filename = "settings.yml"

(*****************************************************************************)
(* Helpers *)
(*****************************************************************************)

(* this causes parse failure in codemap/efuns so commented for now *)
(*
let%test_unit "Lens_envvars.(/)" =
  [%test_eq: Base.string] ("a/b/" / "c/d" / "foo.c") "a/b/c/d/foo.c"
*)

(*
   Treat environment variables with an empty value as if they were unset.

   Since OCaml doesn't provide an 'unsetenv' function (which exists in libc),
   tests that that set environment variable temporarily can't unset them,
   leaving them with the empty value instead.
*)
let env_opt var =
  match Sys.getenv_opt var with
  | Some "" -> None
  | x -> x

(*****************************************************************************)
(* Don't use Sys.getenv* or Unix.getenv* starting from here!  *)
(*****************************************************************************)
(*
   TODO: ensure that the whole application uses our 'env_opt' function.
*)

let env_or conv var default =
  match env_opt var with
  | None -> default
  | Some x -> conv x

let in_env var = env_opt var <> None

let env_truthy var =
  env_opt var |> Option.value ~default:"" |> String.lowercase_ascii |> function
  | "true"
  | "1"
  | "yes"
  | "y" ->
      true
  | _ -> false

(*****************************************************************************)
(* Types and constants *)
(*****************************************************************************)

(* TODO: could we use deriving to automate the generation of
 * env below? [@default = ...] or use ATD?
 *)
type t = {
  lens_url : Uri.t;
  fail_open_url : Uri.t;
  metrics_url : Uri.t;
  app_token : Auth.token option;
  integration_name : string option;
  version_check_url : Uri.t;
  version_check_timeout : int;
  version_check_cache_path : Fpath.t;
  git_command_timeout : int;
  src_directory : Fpath.t;
  user_agent_append : string option;
  user_home_dir : Fpath.t;
  user_dot_lens_dir : Fpath.t;
  user_log_file : Fpath.t;
  user_settings_file : Fpath.t;
  no_color : bool;
  is_ci : bool;
  in_docker : bool;
  in_gh_action : bool;
  sms_scan_id : string option;
  (* deprecated *)
  in_agent : bool;
  min_fetch_depth : int;
  (* TODO(reynir): is this deprecated?! *)
  mock_using_registry : bool;
  (* Whether to disable the v2 config download endpoint. Default: false.
   * Set LENS_DISABLE_CONFIG_DOWNLOAD_V2=1 as a kill switch. *)
  disable_config_download_v2 : bool;
}

(* What about temp? Well we use ocaml stdlib definition of a temp directory.
   This is fine EXCEPT on windows. stdlib on windows expects TEMP (not TMP)
   to be set, and if it's not (which it isn't by default), it uses "." :(
*)

(* less: make it Lazy? so at least not run in ocaml init time before main() *)
let of_current_sys_env () : t =
  let user_home_dir =
    let home_env_var =
      (* In windows USERPROFILE=C:\Users\<user> *)
      if Sys.win32 then "USERPROFILE" else "XDG_CONFIG_HOME"
    in
    match env_opt home_env_var with
    | Some x when Sys_.is_directory x -> Fpath.v x
    | Some _
    | None ->
        Fpath.v (env_or (fun x -> x) "HOME" "/")
  in
  let user_dot_lens_dir = user_home_dir / ".lens" in
  {
    (* lens_url is set by env vars $LENS_URL | $LENS_APP_URL, or default *)
    lens_url =
      env_opt "LENS_URL"
      |> Option.value
           ~default:
             (env_opt "LENS_APP_URL"
             |> Option.value ~default:"https://lens.dev")
      |> Uri.of_string;
    fail_open_url =
      env_or Uri.of_string "LENS_FAIL_OPEN_URL"
        (Uri.of_string "https://fail-open.prod.lens.dev/failure");
    metrics_url =
      env_or Uri.of_string "LENS_METRICS_URL" Metrics_.metrics_url;
    app_token =
      Option.map Auth.unsafe_token_of_string (env_opt "LENS_APP_TOKEN");
    (* integration_name can take a label like "funkyintegration" for custom partner integrations *)
    integration_name = env_opt "LENS_INTEGRATION_NAME";
    version_check_url =
      env_or Uri.of_string "LENS_VERSION_CHECK_URL"
        (Uri.of_string "https://lens.dev/api/check-version");
    version_check_timeout =
      env_or int_of_string "LENS_VERSION_CHECK_TIMEOUT" 2;
    version_check_cache_path =
      env_or Fpath.v "LENS_VERSION_CACHE_PATH"
        (Fpath.v (Sys.getcwd ()) / ".cache" / "lens_version");
    git_command_timeout = env_or int_of_string "LENS_GIT_COMMAND_TIMEOUT" 300;
    src_directory = env_or Fpath.v "LENS_SRC_DIRECTORY" (Fpath.v "/src");
    (* user_agent_append is a literal string like "(Docker)" for inclusion in our metrics user agent field *)
    user_agent_append = env_opt "LENS_USER_AGENT_APPEND";
    user_home_dir;
    user_dot_lens_dir;
    user_log_file =
      env_or Fpath.v "LENS_LOG_FILE" (user_dot_lens_dir / "lens.log");
    user_settings_file =
      env_or Fpath.v "LENS_SETTINGS_FILE"
        (user_dot_lens_dir / settings_filename);
    no_color = env_truthy "NO_COLOR" || env_truthy "LENS_COLOR_NO_COLOR";
    is_ci = in_env "CI";
    in_docker = in_env "LENS_IN_DOCKER";
    in_gh_action = in_env "GITHUB_WORKSPACE";
    sms_scan_id = env_opt "LENS_MANAGED_SCAN_ID";
    in_agent = in_env "LENS_AGENT";
    min_fetch_depth = env_or int_of_string "LENS_GHA_MIN_FETCH_DEPTH" 0;
    mock_using_registry = in_env "MOCK_USING_REGISTRY";
    disable_config_download_v2 = env_truthy "LENS_DISABLE_CONFIG_DOWNLOAD_V2";
  }

(* less: make it Lazy? so at least not run in ocaml init time before main() *)
let v : t ref = ref (of_current_sys_env ())

(*****************************************************************************)
(* For testing *)
(*****************************************************************************)

let with_envvars newv f = Common.save_excursion v newv f

let with_envvar envvar str f =
  Testutil_mock.with_setenv envvar str (fun () ->
      with_envvars (of_current_sys_env ()) f)
