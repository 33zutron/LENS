# Lens local scanner UI

This optional, dependency-free Python web UI scans one source file at a time with the Lens CLI. The server listens on `127.0.0.1` by default, accepts supported text source files up to 1 MB, and removes each temporary upload as soon as its scan finishes.

## Requirements

- Python 3.9 or newer
- A built Lens CLI in `cli/.venv` (follow the repository's [developer setup](../AGENTS.md#developer-setup))

The GUI does not install or build the scanner itself. It uses `cli/.venv/Scripts/lens.exe` on Windows and `cli/.venv/bin/lens` on macOS/Linux.

## Run locally

From the repository root, start the GUI:

```sh
# Windows PowerShell
python .\gui\server.py

# macOS / Linux
python3 ./gui/server.py
```

Open <http://127.0.0.1:8765>. Stop the server with `Ctrl+C` in the terminal. Use `--port 9000` to choose a different port or `--no-open` to keep the server from opening a browser automatically.

## Files

- `server.py` — local HTTP server, upload validation, and CLI invocation
- `index.html` — browser interface and finding display
- `rules.yml` — starter rules for dynamic `eval` calls and likely hard-coded credentials in Python, JavaScript, and TypeScript

Uploaded source is scanned locally and is not sent to an external service by this UI. This small starter rule set is illustrative and is not a complete security audit.
