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
   Parse and interpret '.lensignore' files.

   Original implementation: ignores.py

   The legacy lensignore behavior is irregular and we're trying to move
   away from it and align closely with gitignore behavior.

   Old behavior:
   Here are the differences with gitignore listed in the legacy documentation:
   - '!' pattern negations aren't supported
   - character range patterns aren't supported
   - ':include' directives are a lensignore addition
   - '.lensignore' files placed anywhere in the tree are ignored (?)

   New behavior:
   - support '!' and character ranges to conform to gitignore syntax
   - ':include' is still supported in '.lensignore' files but
     not recursively (included files must obey strict Gitignore syntax).

   Support for negated patterns ('!') allows a .lensignore to
   undo exclusions made in an included '.gitignore'.

   Note that at some point before v2 became the default,
   any '.gitignore' files would be loaded in Git project just like
   '.lensignore' files. While this allowed '.lensignore' files
   to follow the Gitignore syntax strictly, it was causing Git-tracked
   files to be Lensignored if they were Gitignored, causing a new
   behavior for users migrating from v1 to v2. Instead, we decided to keep
   the ':include' extension.
*)
open Fpath_.Operators

type default_lensignore_patterns = Empty | Lens_scan_legacy
type exclusion_mechanism = { use_lensignore_files : bool }

(*
   The default lensignore used when no .lensignore exists
   at the project root.
*)
let default_lensignore_for_lens_scan =
  (*
     WARNING: The file "default.lensignore" is loaded by lens-docs
     to produce Lens's online documentation.
     Don't rename it or move without updating the GitHub URL consulted
     by lens-docs!
  *)
  [%blob "default.lensignore"]

let default_lensignore_filename = ".lensignore"

let lensignore_files ~filename : Gitignore.gitignore_filename =
  {
    source_kind = "lensignore";
    filename;
    format = Gitignore.Legacy_lensignore;
  }

let contents_of_builtin_lensignore = function
  | Empty -> ""
  | Lens_scan_legacy -> default_lensignore_for_lens_scan

let create ?(cli_patterns = [])
    ?(lensignore_filename = default_lensignore_filename)
    ~default_lensignore_patterns ~exclusion_mechanism ~project_root () =
  let root_anchor = Glob.Pattern.root_pattern in
  let default_patterns =
    Parse_gitignore.from_string ~name:"default lensignore patterns"
      ~source_kind:"default" ~anchor:root_anchor
      (contents_of_builtin_lensignore default_lensignore_patterns)
  in
  let cli_patterns =
    List.concat_map
      (Parse_gitignore.from_string ~name:"exclude pattern from command line"
         ~source_kind:"exclude" ~anchor:root_anchor)
      cli_patterns
  in
  let default_lensignore_file_level =
    Gitignore_level_index.of_parsed_patterns
      ~level_kind:"default lensignore patterns" ~source_name:"<built-in>"
      default_patterns
  in
  let cli_level =
    Gitignore_level_index.of_parsed_patterns
      ~level_kind:"command-line includes/excludes" ~source_name:"<command line>"
      cli_patterns
  in
  let kinds_of_ignore_files_to_consult =
    (* We used to load '.gitignore' files as well here but this plan was
       abandoned. *)
    if exclusion_mechanism.use_lensignore_files then
      [ lensignore_files ~filename:lensignore_filename ]
    else []
  in
  (*
     Check if there is a top-level '.lensignore'. If not, use builtins.

     We don't check for '.lensignore' down the tree, so if a user needs
     to override the default lensignore rules, they need at least an
     empty root '.lensignore' file.
  *)
  let root_lensignore_exists =
    let root_dir = Ppath.to_fpath ~root:project_root Ppath.root in
    let lensignore_path = root_dir / lensignore_filename in
    Sys_.Fpath.exists lensignore_path
  in

  (*
     This condition determines whether the default lensignore rules
     should apply.
  *)
  let use_default_lensignore =
    exclusion_mechanism.use_lensignore_files && not root_lensignore_exists
  in

  let higher_priority_levels =
    if use_default_lensignore then
      (* use the built-in lensignore rules in the absence of a root
         '.lensignore' file *)
      [ default_lensignore_file_level; cli_level ]
    else [ cli_level ]
  in
  let gitignore_filter =
    Gitignore_filter.create ~higher_priority_levels
      ~gitignore_filenames:kinds_of_ignore_files_to_consult ~project_root ()
  in
  gitignore_filter
