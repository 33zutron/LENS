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
(* A Lens.dev token representing your identity.
 * This is stored in ~/.lens/settings.yml and initially fetched
 * from https://lens.dev during 'lens login'
 *)
type token

(* to be used in headers *)
val string_of_token : token -> string

(* ("Authorisation:", "Bearer <token>") *)
val auth_header_of_token : token -> string * string

(* TODO: should require a lens_dev capa or lens_settings capa *)
val unsafe_token_of_string : string -> token

val well_formed : token -> bool
(** [well_formed token] checks that the authentication token is structured as
    expected. Currently this just checks if the string is non-empty *)

val equal : token -> token -> bool
