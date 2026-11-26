(*
   Copyright (c) 2024-2025 Lens Inc.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public License
   version 2.1 as published by the Free Software Foundation.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the file
   LICENSE for more details.
*)
let src = Logs.Src.create "lens"

module Log = (val Logs.src_log src : Logs.LOG)

let help_msg =
  {|
If you want to show the logs of a particular library
(e.g., the lens targeting library), you'll need to adjust the
LENS_LOG_SRCS environment variable as in

  LENS_LOG_SRCS="lens.targeting" lens ... --debug

or for olens you can use it with any log level as in

  LENS_LOG_SRCS="lens.targeting" ./bin/olens ... --verbose

You can see the list of possible libraries above in this log as in
...
[00.04][DEBUG](default): Skipping logs for lens.targeting
...
[00.04][DEBUG](default): Skipping logs for commons.pcre
...
For more information, See
https://www.notion.so/lens/Logging-in-lens-lens-core-olens-67c9046fa53744728d9d725a5a244f64
|}

(*
   TODO: add some --lens-log-xxx flags in olens CLI for the envvars so
   they can be set also with CLI flags and will be part of the man page.
*)
let with_setup ?log_to_file ?(log_to_otel = false) ?require_one_of_these_tags
    ?(quiet_log_setup = false) ?(color = Console.Auto) ~level func =
  UConsole.with_setup color @@ fun () ->
  (* We override the default use of LOG_XXX env var in Logs_.setup() with
   * LENS_LOG_XXX env vars because Gitlab was reporting perf problems due
   * to all the logging produced by Lens. Indeed, Gitlab CI itself is running
   * jobs with LOG_LEVEL=debug, so better to use a different name for now.
   * LATER: once we migrate most of our logs to use Logs.src, we should have
   * far less logging by default, even in debug level, so we can maybe restore
   * the use of the standard LOG_LEVEL envvar.
   *
   * The PYTEST_XXX env vars allows modifying the logging behavior of pytest
   * tests since pytest clears the environment except for variables starting
   * with "PYTEST_".
   * LATER: once we remove pylens and switch from pytest to Testo, we
   * can get rid of those PYTEST_xxx env vars.
   *)
  (* currently only additional reporter is otel. Only set to true when --trace
     is passed *)
  let additional_reporters =
    if log_to_otel then [ Logging.(attach_otel_reporter ?attributes:None) ]
    else []
  in
  (* If we're going to log to otel, let's by default log info since that's
     incredibly useful for debugging. When we see logs from otel, we may not
     know the deployment/user or able to ask them to run with a different
     logging level.

     NOTE that pylens (most) users WILL NOT see these logs anyways as
     pylens eats the stderr and doesn't print it out (unless lens-core
     exits abnormally, in which case this may be useful anyways). OLens users
     will, but there's not a good way around that right now...
  *)
  (* Datadog and other tools for viewing logs sent to otel make it easy to
     filter by log level, so maybe we should send all? But that'll be expensive
     ... *)
  let level =
    match level with
    | Some Logs.Warning
    | Some Logs.Error
    | Some Logs.App
    | None
      when log_to_otel ->
        Some Logs.Info
    | _ -> level
  in
  Logs_.with_setup ~highlight_setting:color ?log_to_file
    ?require_one_of_these_tags ~additional_reporters
    ~read_level_from_env_vars:
      [ "PYTEST_LENS_LOG_LEVEL"; "LENS_LOG_LEVEL" ]
    ~read_srcs_from_env_vars:[ "PYTEST_LENS_LOG_SRCS"; "LENS_LOG_SRCS" ]
    ~read_tags_from_env_vars:[ "PYTEST_LENS_LOG_TAGS"; "LENS_LOG_TAGS" ]
    ~quiet_log_setup ~level (fun () ->
      if not quiet_log_setup then (
        Logs.debug (fun m ->
            m "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        Logs.debug (fun m -> m "%s" help_msg);
        Logs.debug (fun m ->
            m "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"));
      func ())
