(*
   Copyright (c) 2026 Lens Inc.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public License
   version 2.1 as published by the Free Software Foundation.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the file
   LICENSE for more details.
*)

(* Coupling: cli/src/lens/telemetry.py _OTEL_ENDPOINT_ALIASES. *)
let default_trace_endpoint = Uri.of_string "https://telemetry.lens.dev"
let default_dev_endpoint = Uri.of_string "https://telemetry.dev2.lens.dev"
let default_local_endpoint = Uri.of_string "http://localhost:4318"

let resolve (s : string) : Uri.t =
  match s with
  | "lens-prod" -> default_trace_endpoint
  | "lens-dev" -> default_dev_endpoint
  | "lens-local" -> default_local_endpoint
  | url -> Uri.of_string url
