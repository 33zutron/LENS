{
  src ? ./cli,
}:
{
  pkgs,
  lens,
  uv2nix,
  pyproject-nix,
  pyproject-build-systems,
}:
# We use uv2nix to do python nix stuff
# https://pyproject-nix.github.io/uv2nix/usage/getting-started.html
let
  python = pkgs.python3;
  inherit (pkgs.callPackages pyproject-nix.build.util { }) mkApplication;

  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = src; };
  # overlay of all python packages that are lens dependencies
  pythonOverlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };
  # Editable for dev environment, so we can edit the source code directly
  # and still have the cli command lens work
  editableOverlay = workspace.mkEditablePyprojectOverlay {
    root = "$REPO_ROOT";
  };
  # generate the python packages, one is
  pythonSet =
    (pkgs.callPackage pyproject-nix.build.packages {
      inherit python;
    }).overrideScope
      (
        pkgs.lib.composeManyExtensions [
          pyproject-build-systems.overlays.wheel
          pythonOverlay
        ]
      );
  venv = pythonSet.mkVirtualEnv "pylens-env" workspace.deps.default;

  devPythonSet = pythonSet.overrideScope editableOverlay;
  devVenv = devPythonSet.mkVirtualEnv "pylens-dev-env" workspace.deps.all;

  devPkgs = [
    devVenv
    pkgs.uv
  ];
  devEnv = {
    UV_NO_SYNC = "1"; # nix manages the packages so don't let uv do it
    UV_PYTHON_DOWNLOADS = "never"; # don't let uv manage downloads
    UV_PYTHON = devPythonSet.python.interpreter; # force uv to use our python
    VIRTUAL_ENV = devVenv; # for type checkers
  };

  pylens =
    (mkApplication {
      inherit venv;
      package = pythonSet.lens;
    }).overrideAttrs
      (old: {
        nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.makeBinaryWrapper ];
        # add ${lens}/bin to PATH so lens can find its ocaml binaries
        postInstall = (old.postInstall or "") + ''
          wrapProgram $out/bin/lens \
            --prefix PATH : ${pkgs.lib.makeBinPath [ lens ]}
          wrapProgram $out/bin/pylens \
            --prefix PATH : ${pkgs.lib.makeBinPath [ lens ]}
        '';
      });
in
{
  pkg = pylens;
  inherit devEnv devPkgs;
}
