<br />
<p align="center">
  <a href="https://lens.dev">
    <picture>
      <source media="(prefers-color-scheme: light)" srcset="images/lens-logo-light.svg">
      <source media="(prefers-color-scheme: dark)" srcset="images/lens-logo-dark.svg">
      <img src="https://raw.githubusercontent.com/lens/lens/develop/images/lens-logo-light.svg" height="100" alt="Lens logo"/>
    </picture>
  </a>
</p>
<h2 align="center">
  Code scanning at ludicrous speed.
</h2>
<p align="center">
  <a href="https://formulae.brew.sh/formula/lens">
    <img src="https://img.shields.io/homebrew/v/lens?style=flat-square" alt="Homebrew" />
  </a>
  <a href="https://pypi.org/project/lens/">
    <img alt="PyPI" src="https://img.shields.io/pypi/v/lens?style=flat-square&color=blue">
  </a>
  <a href="https://lens.dev/docs/">
      <img src="https://img.shields.io/badge/docs-lens.dev-purple?style=flat-square" alt="Documentation" />
  </a>
  <a href="https://go.lens.dev/slack">
    <img src="https://img.shields.io/badge/slack-3.5k%20members-green?style=flat-square" alt="Join Lens community Slack" />
  </a>
  <a href="https://github.com/lens/lens/issues/new/choose">
    <img src="https://img.shields.io/badge/issues-welcome-green?style=flat-square" alt="Issues welcome!" />
  </a>
  <a href="https://github.com/lens/lens#readme">
    <img src="https://img.shields.io/github/stars/lens/lens?label=GitHub%20Stars&style=flat-square" alt="Star Lens on GitHub" />
  </a>
  <a href="https://hub.docker.com/r/lens/lens">
    <img src="https://img.shields.io/docker/pulls/lens/lens.svg?style=flat-square" alt="Docker Pulls" />
  </a>
  <a href="https://hub.docker.com/r/lens/lens">
    <img src="https://img.shields.io/docker/pulls/lens/lens.svg?style=flat-square" alt="Docker Pulls (Old)" />
  </a>
  <a href="https://twitter.com/intent/follow?screen_name=lens">
    <img src="https://img.shields.io/twitter/follow/lens?label=Follow%20lens&style=social&color=blue" alt="Follow @lens on Twitter" />
  </a>
</p>
</br>

Lens is a fast, open-source, static analysis tool that searches code, finds bugs, and enforces secure guardrails and coding standards. Lens [supports 30+ languages](#language-support) and can run in an IDE, as a pre-commit check, and as part of CI/CD workflows.

Lens is semantic grep for code. While running `grep "2"` would only match the exact string _2_, Lens would [match `x = 1; y = x + 1` when searching for _2_](https://lens.dev/playground/s/5rKgj). Lens rules look like the code you already write; no abstract syntax trees, regex wrestling, or painful DSLs.

Note that in security contexts, Lens Community Edition will miss many true positives as it can only analyze code within the boundaries of a single function or file. If you want to use Lens for security purposes (**SAST**, **SCA**, or **secrets scanning**), the Lens AppSec Platform is strongly recommended since it adds the following critical capabilities:

1. Improved core analysis capabilities (cross-file, cross-function, data-flow reachability) that greatly reduce false positives by 25% and increase detected true positives by 250%
2. Contextual post-processing of findings with Lens Assistant (AI) to further reduce noise by [~20%](https://a.storyblok.com/f/151984/x/2d12dc0223/whitepaper_-ai-powered-appsec-engineer-automate.pdf?cv=1728584410408).  In addition, Assistant enriches findings with tailored, step-by-step remediation guidance that humans find actionable >80% of the time.
3. Customizable policies and seamless integration into developer workflows, giving security teams granular control over where, when, and how different findings are presented to developers (IDE, PR comment, etc.)

The Lens AppSec Platform works out-of-the-box with 20000+ proprietary rules across SAST, SCA, and secrets. Pro rules are written and maintained by the Lens security research team and are highly accurate, meaning AppSec teams can feel confident bringing findings directly to developers without slowing them down.

Lens analyzes code locally on your computer or in your build environment: **by default, code is never uploaded**. [Get started →.](#getting-started-)

<a href="#option-1-getting-started-from-the-cli">
<img src="https://raw.githubusercontent.com/lens/lens/develop/images/lens-scan-cli.jpg" alt="Lens CLI image"/></a>

### Language support

**Lens Code** supports 30+ languages, including:

Apex · Bash · C · C++ · C# · Clojure · Dart · Dockerfile · Elixir · HTML · Go · Java · JavaScript · JSX · JSON · Julia · Jsonnet · Kotlin · Lisp · Lua · OCaml · PHP · Python · R · Ruby · Rust · Scala · Scheme · Solidity · Swift · Terraform · TypeScript · TSX · YAML · XML · Generic (ERB, Jinja, etc.)

**Lens Supply Chain** supports 12 languages across 15 package managers, including:

C# (NuGet) · Dart (Pub) · Go (Go modules, `go mod`) · Java (Gradle, Maven) · Javascript/Typescript (npm, Yarn, Yarn 2, Yarn 3, pnpm) · Kotlin (Gradle, Maven) · PHP (Composer) · Python (pip, pip-tool, Pipenv, Poetry) · Ruby (RubyGems) · Rust (Cargo) · Scala (Maven) · Swift (SwiftPM)

For more information, see [Supported languages](https://lens.dev/docs/supported-languages/).

### Getting started 🚀

1. [From the Lens AppSec Platform](#option-1-getting-started-from-the-lens-appsec-platform-recommended)
2. [From the CLI](#option-2-getting-started-from-the-cli)

For new users, we recommend starting with the [Lens AppSec Platform](#option-1-getting-started-from-the-lens-appsec-platform-recommended) because it provides a visual interface, a demo project, result triaging and exploration workflows, and makes setup in CI/CD fast. Scans are still local and code isn't uploaded. Alternatively, you can also start with the CLI and navigate the terminal output to run one-off searches.

### Option 1: Getting started from the Lens Appsec Platform (Recommended)

<a href="https://go.lens.dev/login-ghrmgo"  target="_blank"><img src="https://raw.githubusercontent.com/lens/lens/develop/images/lens-main-image.jpg" alt="Lens platform image"/> </a>

1.  Register on <a href="https://go.lens.dev/login-ghrmgo" target="_blank">lens.dev</a>

2.  Explore the demo findings to learn how Lens works

3.  Scan your project by navigating to `Projects > Scan New Project > Run scan in CI`

4.  Select your version control system and follow the onboarding steps to add your project. After this setup, Lens will scan your project after every pull request.

5.  [Optional] If you want to run Lens locally, follow the steps in the CLI section.

### Notes:

If there are any issues, <a href="https://go.lens.dev/slack" target="_blank">please ask for help in the Lens Slack</a>.

### Option 2: Getting started from the CLI

1. Install Lens CLI

    ```
    # For macOS
    # preferred: install through pipx (https://pipx.pypa.io/stable/how-to/install-pipx.html)
    pipx install lens

    # preferred: install through uv (https://docs.astral.sh/uv/getting-started/installation/)
    uv tool install lens

    # best-effort: install through homebrew (maintained on a best-effort basis; often lags behind the latest release)
    brew install lens

    # For Ubuntu/WSL/Linux/macOS
    $ python3 -m pip install lens

    # To try Lens without installation run via Docker
    $ docker run -it -v "${PWD}:/src" lens/lens lens login
    $ docker run -e LENS_APP_TOKEN=<TOKEN> --rm -v "${PWD}:/src" lens/lens lens ci
    ```

1. Run `lens login` to create your account and login to Lens. This step is optional, but logging into Lens gets you access to:

    - [Lens Supply Chain](https://lens.dev/products/lens-supply-chain?utm_medium=readme&utm_source=github&utm_content=ssc-product): A dependency scanner that detects reachable vulnerabilities in third party libraries
    - [Lens Code's Pro rules](https://lens.dev/products/lens-code?utm_medium=readme&utm_source=github&utm_content=code-pro-rules): 600+ high confidence rules written by Lens's security research team
    - [Lens Code's Pro engine](https://lens.dev/products/pro-engine?utm_medium=readme&utm_source=github&utm_content=pro-engine): An advanced code analysis engine, designed to detect complex vulnerabilities, and reduce false positives

1. Go to your app's root directory and run `lens ci`. This will scan your project to check for vulnerabilities in your source code and its dependencies.

1. Try writing your own query interactively with `-e`. For example, a check for Python == where the left and right hand sides are the same (potentially a bug):
    `$ lens -e '$X == $X' --lang=py path/to/src`

### Local file scanning UI

This repository includes an optional local web interface for scanning a single source file with starter rules. Build the Lens CLI using the [developer setup instructions](AGENTS.md#developer-setup), then run the UI from the repository root:

```sh
# Windows PowerShell
python .\gui\server.py

# macOS / Linux
python3 ./gui/server.py
```

Open <http://127.0.0.1:8765>. The UI accepts supported text source files up to 1 MB, scans them with the local Lens CLI, and deletes each temporary upload after scanning. See [`gui/README.md`](gui/README.md) for details.

### Lens Ecosystem

The Lens ecosystem includes the following:

- [Lens Community Edition](https://lens.dev/docs/cli-reference/) - The open-source program analysis engine at the heart of everything. Suitable for ad-hoc use cases with a high tolerance for false positives - think consultants, security auditors, or pentesters.

- [Lens AppSec Platform](https://lens.dev/login?utm_medium=readme&utm_source=github&utm_content=appsec-platform) - Easily orchestrate and scale SAST, SCA, and Secrets scanning across an organization, with no risk of overwhelming developers.  Customize which findings developers see, where they see them, and integrate with CI providers like GitHub, GitLab, CircleCI, and more. Includes both free and paid tiers.

  - [Lens Code (SAST)](https://lens.dev/products/lens-code?utm_medium=readme&utm_source=github&utm_content=lens-code) - Make real progress on your vulnerability backlog with SAST that minimizes noise and empowers developers to quickly fix issues on their own, even if they have no security knowledge. Easy to deploy secure guardrails and tailored, step-by-step remediation guidance mean developers actually fix issues since they don't feel slowed down.

  - [Lens Supply Chain (SSC)](https://lens.dev/products/lens-supply-chain?utm_medium=readme&utm_source=github&utm_content=ssc) - A high-signal dependency scanner that detects reachable vulnerabilities in open source third-party libraries and functions.

  - [Lens Secrets (Secrets scanning)](https://lens.dev/blog/2023/introducing-lens-secrets/) - Secrets detection that uses semantic analysis, improved entropy analysis, and validation to accurately surface sensitive credentials in the developer workflow.

  - [Lens Assistant (AI)](https://lens.dev/products/lens-code/assistant?utm_medium=readme&utm_source=github&utm_content=assistant) - Assistant is an AI-powered AppSec engineer that helps both developers and AppSec teams prioritize, triage, and remediate Lens findings at scale. Humans agree with Assistant auto-triage decisions 97% of the time, and rate generated remediation guidance as helpful 80% of the time. For an overview of how Assistant works, [read this overview](https://a.storyblok.com/f/151984/x/2d12dc0223/whitepaper_-ai-powered-appsec-engineer-automate.pdf?cv=1728584410408).

- [Lens MCP Server](https://github.com/lens/lens/tree/develop/cli/src/lens/mcp) - A [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server that lets AI coding assistants run Lens scans directly. Integrates with Cursor, VS Code, Windsurf, Claude Desktop, and more. Run `lens mcp` to start it locally.

  - **Hooks** - Automatically trigger Lens scans as you code.
  - **Skills / Prompts** - Built-in MCP prompts like `write_custom_lens_rule` help AI assistants write accurate Lens rules.
  - **Claude Code plugin** - Available on the official marketplace and via the [lens/mcp-marketplace](https://github.com/lens/mcp-marketplace) repo: `/plugin marketplace add lens/mcp-marketplace`
  - **Cursor plugin** - Available on the official marketplace and via the [lens/cursor-plugin](https://github.com/lens/cursor-plugin) repo.

Additional resources:

- [Lens Playground](https://lens.dev/editor) - An online interactive tool for writing and sharing rules.
- [Lens Registry](https://lens.dev/explore) - 2,000+ community-driven rules covering security, correctness, and dependency vulnerabilities.

Join hundreds of thousands of other developers and security engineers already using Lens at companies like GitLab, Dropbox, Slack, Figma, Shopify, HashiCorp, Snowflake, and Trail of Bits.

Lens is developed and commercially supported by [Lens, Inc., a software security company](https://lens.dev).

### Lens Rules

Lens rules look like the code you already write; no abstract syntax trees, regex wrestling, or painful DSLs. Here's a quick rule for finding Python `print()` statements.

Run it online in Lens’s Playground by [clicking here](https://lens.dev/playground/r/3qUzQD/ievans.print-to-logger).

<p align="center">
    <a href="https://lens.dev/playground/r/3qUzQD/ievans.print-to-logger"  target="_blank"><img src="https://raw.githubusercontent.com/lens/lens/develop/images/lens-example-rules-editor.jpg" width="582" alt="Lens rule example for finding Python print() statements" /></a>
</p>

#### Examples

Visit [Docs > Rule examples](https://lens.dev/docs/writing-rules/rule-ideas/) for use cases and ideas.

| Use case                          | Lens rule                                                                                                                                                                                                                                                                                                                                                                                                |
| :-------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Ban dangerous APIs                | [Prevent use of exec](https://lens.dev/playground/s/lglB)                                                                                                                                                                                                                                                                                                                                                |
| Search routes and authentication  | [Extract Spring routes](https://lens.dev/playground/s/Y6wD)                                                                                                                                                                                                                                                                                                                                              |
| Enforce the use secure defaults   | [Securely set Flask cookies](https://lens.dev/playground/s/6KwW)                                                                                                                                                                                                                                                                                                                                         |
| Tainted data flowing into sinks   | [ExpressJS dataflow into sandbox.run](https://lens.dev/playground/s/qEpR)                                                                                                                                                                                                                                                                                                                                |
| Enforce project best-practices    | [Use assertEqual for == checks](https://lens.dev/playground/s/oEox), [Always check subprocess calls](https://lens.dev/playground/s/zENk)                                                                                                                                                                                                                                                              |
| Codify project-specific knowledge | [Verify transactions before making them](https://lens.dev/playground/s/p8zk)                                                                                                                                                                                                                                                                                                                             |
| Audit security hotspots           | [Finding XSS in Apache Airflow](https://lens.dev/playground/s/KPwj), [Hardcoded credentials](https://lens.dev/playground/s/2Br8)                                                                                                                                                                                                                                                                      |
| Audit configuration files         | [Find S3 ARN uses](https://lens.dev/playground/s/jEKD)                                                                                                                                                                                                                                                                                                                                                   |
| Migrate from deprecated APIs      | [DES is deprecated](https://lens.dev/playground/r/java.lang.security.audit.crypto.des-is-deprecated.des-is-deprecated), [Deprecated Flask APIs](https://lens.dev/playground/r/python.flask.maintainability.deprecated.deprecated-apis.flask-deprecated-apis), [Deprecated Bokeh APIs](https://lens.dev/playground/r/python.bokeh.maintainability.deprecated.deprecated_apis.bokeh-deprecated-apis) |
| Apply automatic fixes             | [Use listenAndServeTLS](https://lens.dev/playground/s/1Ayk)                                                                                                                                                                                                                                                                                                                                              |

### Extensions

Visit [Docs > Extensions](https://lens.dev/docs/extensions/) to learn about using Lens in your editor or pre-commit. When integrated into CI and configured to scan pull requests, Lens will only report issues introduced by that pull request; this lets you start using Lens without fixing or ignoring pre-existing issues!

### Documentation

Browse the full Lens [documentation on the website](https://lens.dev/docs). If you’re new to Lens, check out [Docs > Getting started](https://lens.dev/docs/getting-started/) or the [interactive tutorial](https://lens.dev/learn).

### Metrics

Using remote configuration from the [Registry](https://lens.dev/r) (like `--config=p/ci`) reports pseudonymous rule metrics to lens.dev.

When using configs from local files (like `--config=xyz.yml`), metrics are sent only when the user is logged in.

To disable Registry rule metrics, use `--metrics=off`.

The Lens [privacy policy](https://lens.dev/docs/metrics) describes the principles that guide data-collection decisions and the breakdown of the data that are and are not collected when the metrics are enabled.

### More

- [Frequently asked questions (FAQs)](https://lens.dev/docs/faq/)
- [Contributing](https://lens.dev/docs/contributing/contributing/)
- [Build instructions for developers](INSTALL.md)
- [Ask questions in the Lens community Slack](https://go.lens.dev/slack)
- [CLI reference and exit codes](https://lens.dev/docs/cli-usage)
- [Lens YouTube channel](https://www.youtube.com/c/lens)
- [License (LGPL-2.1)](LICENSE)
- [Licensing Lens](https://lens.dev/docs/licensing/)

### Upgrading

To upgrade, run the command below associated with how you installed Lens:

```sh
# Using pipx
$ pipx upgrade lens

# Using uv tool command
$ uv tool upgrade lens

# Using Homebrew
$ brew upgrade lens

# Using Docker
$ docker pull lens/lens:latest
```
