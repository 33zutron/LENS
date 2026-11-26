#!/usr/bin/env python3
# This file is the Lens CLI entry point of the Lens pip package,
# the Lens HomeBrew package, and the Lens Docker container.
#
# In the future we may have different entry points when packaging Lens
# with Cargo, Npm, Opam, or even with Docker (ideally the entry point would
# be src/main/Main.ml without any wrapper around once olens is finished).
#
# The main purpose of this small wrapper is to dispatch
# either to the legacy pylens (see the pylens script in this
# directory), or to the new olens (accessible via the lens-core binary
# under cli/src/lens/bin/ or somewhere in the PATH), or even to
# olens-pro (accessible via the lens-core-proprietary binary).
#
# It would be faster and cleaner to have a Bash script instead of a Python
# script here, but actually the overhead of Python here is just 0.015s.
# Moreover, it is sometimes hard from a Bash script to find where is installed
# lens-core, but it is simple from Python because you can simply use
# importlib.resources. We could also use 'pip show lens' from a Bash script
# to find lens-core, but will 'pip' be in the PATH? Should we use 'pip' or
# 'pip3'?
# Again, it is simpler to use a Python script and leverage importlib.resources.
# Another alternative would be to always have lens-core in the PATH,
# but when trying to put this binary in cli/bin, setuptools is yelling
# and does not know what to do with it. In the end, it is simpler to use
# a *Python* script when installed via a *Python* package manager (pip).
#
# NOTE: if you modify this file, you will need to `pipenv install --dev`
# if you want to test the change under `pipenv shell`.
import importlib.resources
import os
import platform
import subprocess
import sys
import sysconfig
import warnings

# alt: you can also add '-W ignore::DeprecationWarning' after the python3 above,
# but setuptools and pip adjust this line when installing lens so we need
# to do this instead.

warnings.filterwarnings("ignore", category=DeprecationWarning)

# Add the directory containing this script in the PATH, so the pylens
# script will also be in the PATH.
# Some people don't have lens in their PATH and call it instead
# explicitly as in /path/to/somewhere/bin/lens, but this means
# that calling pylens from olens would be difficult because
# it would not be in the PATH (we would need to pass its path to olens,
# which seems more complicated).
# nosem: no-env-vars-on-top-level
PATH = os.environ.get("PATH", "")
# nosem: no-env-vars-on-top-level
os.environ["PATH"] = PATH + os.pathsep + sysconfig.get_path("scripts")

IS_WINDOWS = platform.system() == "Windows"

PRO_FLAGS = ["--pro", "--pro-languages", "--pro-intrafile"]

if IS_WINDOWS:
    # NOTE: we conditionally import colorama to avoid importing it
    # unnecessarily on other platforms in the entrypoint script, which needs to
    # be as 'light' as possible.
    from colorama.winterm import enable_vt_processing

    # On Windows, enable virtual terminal processing to correctly process ANSI
    # escape sequences for pretty, colored output. We want to enable this as
    # early as possible to correctly process ANSI escape sequences in all the
    # subcommands both in olens and pylens. See
    # https://learn.microsoft.com/en-us/windows/console/setconsolemode for more
    # information.
    enable_vt_processing(sys.stdout.fileno())
    enable_vt_processing(sys.stderr.fileno())


class CoreNotFound(Exception):
    def __init__(self, value):
        self.value = value
        super().__init__(value)

    def __str__(self):
        return self.value


# Similar to cli/src/lens/engine.py check_is_correct_pro_version
def is_correct_pro_version(core_path):
    """
    We want to be careful about what we import here in order to keep this
    script lightweight. However, this file just defines a single constant and
    it takes well under a millisecond to import this.

    This can be verified with `time python -c 'import lens; print(lens.__VERSION__)'`
    """
    from lens import __VERSION__

    # Duplicate of cli/src/lens/lens_core.py pro_version_stamp_path
    stamp_path = core_path.parent / "pro-installed-by.txt"
    if stamp_path.is_file():
        with stamp_path.open("r") as f:
            version_at_install = f.readline().strip()
            return version_at_install == __VERSION__
    else:
        return False


# similar to cli/src/lens/lens_core.py compute_executable_path()
def find_lens_core_path(pro=False, extra_message=""):
    if pro:
        core = "lens-core-proprietary"
    else:
        core = "lens-core"

    if IS_WINDOWS:
        core += ".exe"

    # First, try the packaged binary.
    try:
        # the use of .path causes a DeprecationWarning hence the
        # filterwarnings above
        with importlib.resources.path("lens.bin", core) as path:
            if path.is_file():
                if pro and not is_correct_pro_version(path):
                    raise CoreNotFound(
                        f"The installed version of {core} is out of date.{extra_message}"
                    )
                return str(path)
    except (FileNotFoundError, ModuleNotFoundError):
        pass

    # Second, try in PATH. In certain context such as Homebrew
    # (see https://github.com/Homebrew/homebrew-core/blob/master/Formula/lens.rb)
    # or Docker (see ../../Dockerfile), we actually copy lens-core in
    # /usr/local/bin (or in a bin/ folder in the PATH). In those cases,
    # there is no /.../site-packages/lens-xxx/bin/lens-core.
    # In those cases, we want to grab lens-core from the PATH instead.
    # Lazy import to keep the entry point lightweight
    from lens.executable_lookup import find_executable

    path = find_executable(core)
    if path is not None:
        return path

    from lens.platform_support import intel_macos_guidance
    from lens.platform_support import is_intel_macos

    if not pro and is_intel_macos():
        extra_message += "\n" + intel_macos_guidance(build_from_source=True)
    raise CoreNotFound(
        f"Failed to find {core} in PATH or in the lens package.{extra_message}"
    )


# TODO: we should just do 'execvp("pylens", sys.argv)'
# but this causes some regressions with --test (see PA-2963)
# and autocomplete (see #8359)
# TODO: we should get rid of autocomplete anyway (it's a Python Click
# thing not supported by olens anyway),
# TODO: we should fix --test instead.
# The past investigation of Austin is available in #8360 PR comments
def exec_pylens():
    import lens.main

    sys.exit(lens.main.main())


# We could have moved the code below in a separate 'olens' file, like
# for 'pylens', but we don't want users to be exposed to another command,
# so it is better to hide it.
# We expose 'pylens' because olens itself might need to fallback to
# pylens and it's better to avoid the possibility of an infinite loop
# by simply using a different program name. Morever, in case of big problems,
# we can always tell users to run pylens instead of lens and be sure
# they'll get the old behavior.
def exec_olens():
    argv = sys.argv
    # cmdliner 2.x emits ANSI-styled error/help output whenever TERM is set,
    # with no isatty check (a regression from 1.x, which was always plain).
    # When our own stderr isn't a TTY (piped to a log file, captured by a
    # test harness, etc.), set NO_COLOR so cmdliner reverts to plain output.
    # Skip when the caller has an explicit color preference so force-color
    # tests and users who opt in/out stay in control.
    if (
        not sys.stderr.isatty()
        and not os.environ.get("NO_COLOR")
        and not os.environ.get("FORCE_COLOR")
        and not os.environ.get("LENS_FORCE_COLOR")
    ):
        os.environ["NO_COLOR"] = "1"
    if any(pro_flag in argv for pro_flag in PRO_FLAGS):
        try:
            path = find_lens_core_path(
                pro=True,
                extra_message="\nYou may need to run `lens install-lens-pro`",
            )
        except CoreNotFound as e:
            print(str(e), file=sys.stderr)
            if sys.argv[1] == "ci":
                # CI users usually want things to just work. In particular, if they
                # are running `lens ci --pro` they don't want to have to add an
                # extra step to install-lens-pro. This wrapper doesn't have a way
                # to install lens-pro, however, so have them run legacy `lens`.
                print(
                    "Since `lens ci` was run, defaulting to legacy lens",
                    file=sys.stderr,
                )
                exec_pylens()
            else:
                print(
                    "Attempting to auto-install lens-core-proprietary and retry the command...",
                    file=sys.stderr,
                )

                # Lazy import to keep the entry point lightweight
                from lens.app import auth
                from lens.cli import cli

                # If not logged in, prompt user to log in
                if not auth.is_logged_in_weak():
                    print(
                        "Run `lens login` before running `lens scan --pro`. Or in non-interactive environments, ensure your LENS_APP_TOKEN variable is set correctly.",
                        file=sys.stderr,
                    )
                    sys.exit(2)

                # We already attempted to auto-install in this process tree and so we fail
                if os.environ.get("_LENS_PRO_AUTO_INSTALLED"):
                    print(
                        "install-lens-pro previously reported success but the binary still isn't reachable.",
                        file=sys.stderr,
                    )
                    sys.exit(2)

                # Otherwise, install-lens-pro and try again
                try:
                    cli.main(args=["install-lens-pro"], standalone_mode=False)
                except SystemExit as exc:
                    # If installation failed, we print the error
                    if exc.code not in (0, None):
                        raise

                    # Otherwise, retry the original command now that lens-pro is installed
                    # Environment variable ensures that we don't try to auto-install again if something goes wrong
                    os.environ["_LENS_PRO_AUTO_INSTALLED"] = "1"
                    print(
                        "Lens Pro Engine installed successfully, retrying the original command...",
                        file=sys.stderr,
                    )
                    exec_olens()
                    return

                sys.exit(2)
        # If you call lens-core-proprietary as olens-pro, then we get
        # olens-pro behavior, see lens-proprietary/src/main/Pro_main.ml
        sys.argv[0] = "olens-pro"
    else:
        try:
            path = find_lens_core_path()
        except CoreNotFound as e:
            print(str(e), file=sys.stderr)
            # fatal error, see src/olens/core/Exit_code.ml
            sys.exit(2)

        # If you call lens-core as olens, then we get
        # olens behavior, see src/main/Main.ml
        sys.argv[0] = "olens"
    if IS_WINDOWS:
        # On Windows, os.execvp spawns a background process instead of
        # replacing the current one, which breaks CLI interactivity. Therefore,
        # we use subprocess.run to spawn a process that maintains interactive
        # behavior. We stick with os.execvp on POSIX systems because it
        # correctly replaces the current process, which is the desired behavior
        # and avoids unnecessary extra processes.
        try:
            # nosem: dangerous-subprocess-use-tainted-env-args
            child = subprocess.run(sys.argv, executable=str(path))
        except KeyboardInterrupt:
            # We don't want the stack trace on user interrupt
            print(str("Aborted!"), file=sys.stderr)
            sys.exit(130)
        sys.exit(child.returncode)
    else:
        # nosem: dangerous-os-exec-tainted-env-args
        os.execvp(str(path), sys.argv)


# Needed for similar reasons as in pylens, but only for the legacy
# flag to work
def main():
    # This is a workaround for stdio and stdout encoding issues on Windows.
    # Instead of relying on the users setting PYTHONIOENCODING=utf8 when
    # running on Windows and redirecting the stdout and stderr to files, we do
    # it in the console scripts.
    # https://docs.python.org/3/library/sys.html#sys.stdout
    if IS_WINDOWS and not sys.stdout.isatty():
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")

    # escape hatch for users to pylens in case of problems (they
    # can also call directly 'pylens').
    if "--legacy" in sys.argv:
        sys.argv.remove("--legacy")
        exec_pylens()
    elif "--experimental" in sys.argv:
        exec_olens()
    else:
        # we now default to olens! but this will usually exec
        # back to pylens for most commands (for now)
        # We activate the new CLI UX only when lens is invoked directly
        # (and legacy is not specified)
        # and olens needs to fallback on pylens
        os.environ["LENS_NEW_CLI_UX"] = f"{int(sys.stdout.isatty())}"
        exec_olens()


if __name__ == "__main__":
    main()
