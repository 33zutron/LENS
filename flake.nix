# ## Quick start
#
# Use https://github.com/DeterminateSystems/nix-installer to get Nix easily
# then run `nix develop` to get a shell with all the dependencies
# Run:
#  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
#  make shell # for a shell with all tools OR
#  make nix-lens # to build lens
#
#  ## Overview
#
# This is a Nix file for Lens developers.
#
# Nix is a dependency manager. Nix allows to use just one command
# to get a fully functional correct and near identical development
# environment across any OS, instead of the 10-20 commands it normally takes.
# It's totally opt-in and will not impact anyones work flow.
# See https://shopify.engineering/what-is-nix for more information.
#
# Note that there is also a Nix(OS) file for lens here:
# https://github.com/NixOS/nixpkgs/tree/master/pkgs/tools/security/lens
# so people can install Lens on NixOS.
# However the current file is directed at Lens developers, not Lens users.
#

# What is Nix?
#
# Nix is a package dependency manager for reproducible and correct builds. Nix
# is structured around the concept that each dependency is a function of its
# build dependencies. For example a hello world program takes in GCC and make as
# function arguments, and spits out a hello world binary. What makes this
# reproducible is that nix treats files as pointers, and produces a closure over
# all files in a build system. For example if the hello world depends on a C
# library, then your nix build of hello world won't complete unless you
# explicitly declare said library in your nix configuration. Since all build
# tools made with nix are built this way, nix knows exactly what any dependency
# needs to build, and to run, meaning *all builds are easily reproducible, and
# are not affected by what you may or may not have installed on your system*.

# ### What is the difference with a Dockerfile?
#
# A Dockerfile is a great way to build an entire OS, and run a program in that
# and can be used for development, but has many downsides.
#
# Docker still relies on Linux, and that Linux distro still relies on some
# package manager. This means that even if you use Docker, your environment is
# still not reproducible as packages are not built deterministically like Nix.
# So you can create a Dockerfile building Lens, but you will need a different
# build script + Dockerfile for every system, and you must determine what the
# different distributions all ship and have package wise. Meanwhile this Nix
# file will work (almost) exactly the same across any system.
#
# Docker on many systems like anything Apple Silicon will run an emulator, which
# is very high perf overhead for day to day development. Then your tooling also
# won't take advantage of system specific speedups.
#
# Docker also is a completely different system, so if you are testing/developing
# for Macs, Docker can't help there. Additionally since it is a different system
# you don't have access to any of your tools, such as your IDE, favorite shell
# etc. unless you want to set up a mount + ssh everytime, which is a lot of
# friction.
#
# Think: why is Rust's Cargo, Javascript's NPM, Python's Poetry so popular?
# Because they explicitly declare the dependencies, instead of hoping you have
# said dependencies installed already, or shipping a bash script/Makefile that
# installs them for you.

# ## Why should I care?
#
# Our OCaml code is (mostly) correct because that's a focus of the language
# itself. But it relies on a lot of C code and external dependencies, like
# `libev`, `libcurl`, `tree-sitter` etc. This means that if someone wants to
# build and contribute to Lens, they must install these dependencies, and
# hope that their versions is compatible. For example if you install the OCaml
# packages needed for olens, and then install libev, things won't work, since
# the lwt package needs libev when its initially installed. If you're on mac,
# you also have to tell opam where libev is before installing lwt. So our OCaml
# is correct, but only if you can build it, and only if you build it with the
# right dependencies.

# By using Nix, we can declare all these dependencies explicitly, and then
# anyone across any *nix system can easily build Lens with only one command!
# What's even better, is for regular contributors, these dependencies will auto
# update and rebuild whenever a new dependency is added. So if someone adds a
# dependency for lwt, libev will automatically be pulled in with 0 thought from
# the contributor, and no need to run `make dev-setup` or anything similar.
# Since all of the dependencies are reproducible, they're almost identical no
# matter what system you're on, so if someone runs into a bug in developing, you
# can have more confidence in eliminating a system difference as the source of
# the bug.

# Another bonus is that it's easy to know what version of a dependency you're
# on, e.g. what version of tree-sitter, or what version of OCaml. You can see
# how this also would be good for security :).

# There's a lot more places this can simplify things for us, like CI and
# releases. See future work for more details.

# Finally, nix configurations are written in a functional programming language.
# Don't you want to declare dependencies in a functional language?

# ## Who uses Nix?
#
# Not convinced? Here are some other notable OCaml projects using nix:

# - [dune](https://github.com/ocaml/dune)
# - [merlin](https://github.com/ocaml/merlin)
# - [ocaml-lsp](https://github.com/ocaml/ocaml-lsp)
# - [ocaml-re](https://github.com/ocaml/ocaml-re)

# There's also a ton of projects outside the OCaml world using nix too. Nix is
# battle tested, and has a huge community, with support for almost anything you
# can think of. There's even someone packaging Lens for nix.

# ## Try it out
#
# If you want to see what it's like to use nix, get a clean Linux or macOS box.
# Then [install nix](https://github.com/DeterminateSystems/nix-installer) with
# flake support. Finally run `nix develop`. Now you can run `make core` or any
# make targets in the CLI. That's one command to always be able to build Lens
# vs the 10-20 needed right now, if you're lucky, and then 2-3 every once in
# awhile to keep up to date.

# If you want to reproduce and help with a bug in someones branch, you can just
# run `nix develop` and `make test` to instantly have the same exact environment
# they ran into the bug in. If you're really unsure about if it's a system bug,
# you can run `nix develop -i` to exclude any non nix dependencies completely.

# If you don't use bash run `nix develop -c $SHELL` to get an environment with
# your shell.

# If you want to just build lens and run it you can do `nix run
# ".?submodules=1#"` for lens or `nix run ".?submodules=1#<target>"` where
# target is lens, pylens, olens, or lens-core.

# ## What's the catch?
#
# There's not a real big catch to using nix, except development time to set it
# up, which the PR that introduced this did. A few small catches are that nix can be a little
# slow on a first build, but no more than say `make dev-setup`, and that it uses
# a decent amount of storage space, but again, not much more than any other
# package manager.

# ## Contributing/Maintennance
#
# The maintenance for nix is super low. It automatically pulls in any dependency
# declared in our lens.opam file, which then pulls in any non ocaml
# dependencies those dependencies rely on. If someone adds a new build tool or
# python package, they will have to add the dependency to `flake.nix`. This
# means you have to read some comments then add the name of the package to an
# array somewhere, super easy. If you're interested in doing anything more
# complex, see the future reading section.

# # Future work
# ## Some issues with our current usage of Dune and Opam
#
# Right now our usage of dune is a little incorrect. In every language lens
# tree-sitter dune file (i.e. bash/tree-sitter/lens-bash), we don't pass the
# standard c/c++ flags to compile the C files. This means that the compiler
# provided by nix doesn't know if a c++ file is a c++ file, and fails to include
# the standard c++ library. There's an ongoing PR to fix this logic for nix, but
# really we should add ":standard" to the list of c++ flags in these dune files.
# There's a patch for now in the nix configuration but it's a bit ugly.

# Another issue with our opam usage is we don't declare dependencies on
# libraries provided by lens. I.e. we depend on commons, but don't declare
# that dependency in lens.opam. This breaks some autoresolving things in nix,
# which are patched for now, but would be nice if we fixed our usage of opam.

# ## CI testing
#
# If people like this tool, at some point it'd be great to add a CI workflow
# that ensures all PRs work even with nix. But let's see how this goes first.

# ## Improving our CI
#
# Where nix would smooth things over for us even more is simplifying our CI.
# Right now we have to guess and hope that our CI has the same dependencies as
# what's on our system, and it can be a fight to add any new dependencies, like
# libcurl. Not to mention our workflows differ by system, and it's a pain to
# make sure they all have the right package names. If we use nix in CI, all we
# need is to install nix on the target OS/architecture, then run nix build and
# it can run all build processes, and all e2e tests. Super simple workflow. It
# can even build the wheels, and static versions of Lens we'd want!

# # More reading
#
# Interested in reading more about nix? Here are some hand sources
#
# - [What is Nix](https://shopify.engineering/what-is-nix) - short intro to nix
#   by Shopify Engineering
#
# - [Nix Pills](https://nixos.org/guides/nix-pills/) -long form intro to nix
#
# - [Nix Flakes](https://zero-to-nix.com/concepts/flakes) - intro to the format
#   we use to configure nix
#
# - [opam-nix](https://www.tweag.io/blog/2023-02-16-opam-nix/) - how we nixify
#   opam deps
#
# - [Nix PhD Thesis](https://edolstra.github.io/pubs/phd-thesis.pdf) - Nix
#   creator's PhD thesis on Nix. ~275 pages but really approachable

{
  description = "Lens OSS is a fast, open-source, static analysis tool for searching code, finding bugs, and enforcing code standards at editor, commit, and CI time.";
  nixConfig = {
    extra-substituters = "https://lens.cachix.org";
    extra-trusted-public-keys = "lens.cachix.org-1:waxSNb3ism0Vkmfa31//YYrOC2eMghZmTwy9bvMAGBI=";
    extra-experimental-features = "nix-command flakes";
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    # all the follows here are so we don't use diff versions of
    # nixpkgs/flake-utils than lens. This is good for debugging, and reducing
    # build time/cache size
    opam-nix = {
      url = "github:tweag/opam-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # pin the opam repository to a specific commit! This way we can ensure that
    # things don't break
    opam-repository = {
      url = "github:ocaml/opam-repository";
      flake = false;
    };
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      opam-nix,
      opam-repository,
      pyproject-nix,
      uv2nix,
      pyproject-build-systems,
    }:
    let
      hasSubmodules = !builtins.hasAttr "submodules" self || self.submodules;
      mkLens = import ./lens.nix {
        inherit opam-nix opam-repository hasSubmodules;
      };
      mkPylens = import ./pylens.nix { };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        { pkgs, system, ... }:
        # TODO lens-js
        # needs new emscripten: https://github.com/NixOS/nixpkgs/issues/306649
        # for the special wasm pass
        let
          lensAttrs = mkLens { inherit pkgs system; };
          lens = lensAttrs.pkg;

          pylensAttrs = mkPylens {
            inherit
              pkgs
              lens
              uv2nix
              pyproject-nix
              pyproject-build-systems
              ;
          };
          pylens = pylensAttrs.pkg;

          devShells = import ./devShells.nix {
            inherit pkgs;
            devAttrs = [
              lensAttrs
              pylensAttrs
            ];
          };

        in
        {
          # For a lot of nix commands, nix uses the cwd's flake. So
          #   nix develop
          # will run the current flake. But because lens has submodules we have
          # to specify `.?submodules=1#` to enable checking out submodules`
          #
          # The target of the command is structured
          # `<FLAKE_LOCATION>(?OPTIONAL_PARAMS)#<TARGET>` so you can run
          #   nix run nixpkgs#gcc
          # to run gcc from the default nix repository nixpkgs.
          #
          # But the location is similar to a url! So you can run
          #   nix run github:DeterminateSystems/flake-checker
          # to run DeterminateSystem's
          # cool flake checker, without ever needing to install it or anything! Or
          # other nix users who want to try olens can run
          #   nix run github:lens/lens?submodules=1#olens
          #
          # See: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#types
          # for more on flake refs
          #
          # See: https://nixos.org/manual/nix/stable/command-ref/experimental-commands
          # for other useful commands

          #   nix build ".?submodules=1#<PKG_NAME>"
          # builds the below package leaving it empty builds the default. The
          # output will be linked into the cwd in a folder called "result". Also
          # exports packages for other nix packages to use
          packages = {
            lens-core = lens;
            lens = pylens;
            default = pylens;
          };

          #   nix run ".?submodules=1#<PKG_NAME>"
          # builds and runs the package specified, without linking the output
          # result into the cwd. You can try other nixpkgs similarly by running
          # `nix run nixpkgs#<PKG_NAME>` like `nix run nixpkgs#hello_world`.
          apps = {
            lens-core = {
              type = "app";
              program = "${lens}/bin/lens-core";
            };
            lens = {
              type = "app";
              program = "${pylens}/bin/lens";
            };
            default = {
              type = "app";
              program = "${pylens}/bin/lens";
            };
          };
          #   nix flake check ".?submodules=1#"
          # makes sure the flake is a valid structure, all the derivations are
          # valid, and runs anyting put in checks
          checks = {
            lens = lens.overrideAttrs (_: {
              doCheck = true;
            });
          };

          #   nix fmt
          # formats this file. In the future we can add ocaml, python, and other
          # formatters here to run also
          formatter = pkgs.nixpkgs-fmt;
          #   nix develop -c $SHELL
          # runs this shell which has all dependencies needed to make lens
          devShells = devShells;
        };
    };
}
