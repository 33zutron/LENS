(*
   Copyright (c) 2022-2024 Lens Inc.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public License
   version 2.1 as published by the Free Software Foundation.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the file
   LICENSE for more details.
*)
(*
   Typed access to Lens environment variables (e.g., LENS_IN_DOCKER).
 *)

(* Most (typed) fields below correspond directly to an uppercase environment
 * metavariable with the LENS_ prefix.
 * For example, [git_command_timeout] will contain the content of
 * LENS_GIT_COMMAND_TIMEOUT in the environment (or a default value if
 * it's not in the environment).
 *)
type t = {
  (* $LENS_URL | $LENS_APP_URL *)
  lens_url : Uri.t;
  (* $LENS_FAIL_OPEN_URL *)
  fail_open_url : Uri.t;
  (* $LENS_METRICS_URL *)
  metrics_url : Uri.t;
  app_token : Auth.token option;
  (* $LENS_INTEGRATION_NAME *)
  integration_name : string option;
  (* $LENS_VERSION_CHECK_URL *)
  version_check_url : Uri.t;
  version_check_timeout : int;
  (* .cache/lens_version *)
  version_check_cache_path : Fpath.t;
  git_command_timeout : int;
  (* "/src" *)
  src_directory : Fpath.t;
  (* $LENS_USER_AGENT_APPEND -> "(Docker)" *)
  user_agent_append : string option;
  (* XDG_CONFIG_HOME on *nix, USERPROFILE on windows, or default to HOME or / *)
  user_home_dir : Fpath.t;
  (* user_home_dir/.lens *)
  user_dot_lens_dir : Fpath.t;
  (* $LENS_LOG_FILE or ~/.lens/lens.log  *)
  user_log_file : Fpath.t;
  (* $LENS_SETTINGS_FILE ~/.lens/settings.yml *)
  user_settings_file : Fpath.t;
  (* TODO: Reconcile $LENS_FORCE_COLOR via o_force_color *)
  (* ($NO_COLOR | $LENS_COLOR_NO_COLOR) *)
  no_color : bool;
  is_ci : bool;
  in_docker : bool;
  (* $GITHUB_WORKSPACE *)
  in_gh_action : bool;
  (* Unique identifier for the managed_scan in lens-app
   * $LENS_MANAGED_SCAN_ID
   *)
  sms_scan_id : string option;
  (* $LENS_AGENT (deprecated) *)
  in_agent : bool;
  (* $LENS_xxx *)
  min_fetch_depth : int;
  (* $MOCK_USING_REGISTRY *)
  mock_using_registry : bool;
  (* $LENS_DISABLE_CONFIG_DOWNLOAD_V2 *)
  disable_config_download_v2 : bool;
}

val v : t ref
(** [v] is a reference to environment variables and user settings gathered
    during initialization. This is a reference to allow these settings to
    be modified by tests.
  *)

(* useful to work in cunjonction with with_envvars in testing context *)
val of_current_sys_env : unit -> t

val with_envvars : t -> (unit -> 'a) -> 'a
(** [with_envvars env f] temporarily modifies [v] above with a new [env]
   and run [f] in this new context. This is useful in tests.
 *)

val with_envvar : string -> string -> (unit -> 'a) -> 'a
(** [with_envvar envvar value f] temporarily modifies [v] above
   with a new envvar and run [f] in this new context. This is useful
   in tests.
 *)
