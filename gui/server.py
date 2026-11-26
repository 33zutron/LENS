from __future__ import annotations

import argparse
import json
import os
import secrets
import subprocess
import tempfile
import threading
import webbrowser
from email import policy
from email.parser import BytesParser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[1]
HTML = Path(__file__).with_name("index.html")
RULES = Path(__file__).with_name("rules.yml")
LENS = ROOT / "cli" / ".venv" / (
    "Scripts/lens.exe" if os.name == "nt" else "bin/lens"
)
MAX_UPLOAD_BYTES = 1_000_000
MAX_RESULTS = 2_000
SCAN_TIMEOUT_SECONDS = 120
ALLOWED_EXTENSIONS = {
    ".c", ".cc", ".cpp", ".cs", ".go", ".h", ".html", ".java", ".js",
    ".jsx", ".json", ".kt", ".php", ".py", ".rb", ".rs", ".scala",
    ".sh", ".sql", ".tf", ".ts", ".tsx", ".vue", ".xml", ".yaml", ".yml",
}


class LensGuiServer(ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = True

    def __init__(self, address: tuple[str, int], token: str):
        self.token = token
        self.scan_lock = threading.Lock()
        super().__init__(address, LensGuiHandler)


class LensGuiHandler(BaseHTTPRequestHandler):
    server: LensGuiServer

    def log_message(self, fmt: str, *args: object) -> None:
        print(f"[{self.log_date_time_string()}] {fmt % args}")

    def _send(self, status: int, body: bytes, content_type: str) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header(
            "Content-Security-Policy",
            "default-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self'; img-src 'self' data:",
        )
        self.end_headers()
        self.wfile.write(body)

    def _json(self, status: int, payload: dict[str, object]) -> None:
        self._send(
            status,
            json.dumps(payload).encode("utf-8"),
            "application/json; charset=utf-8",
        )

    def _local_request(self) -> bool:
        host = self.headers.get("Host", "").split(":", 1)[0].lower()
        origin = self.headers.get("Origin")
        if host not in {"127.0.0.1", "localhost"}:
            return False
        if origin:
            parsed = urlparse(origin)
            if parsed.scheme != "http" or parsed.netloc != self.headers.get("Host"):
                return False
        return True

    def do_GET(self) -> None:
        if not self._local_request():
            self._json(403, {"error": "Local requests only."})
            return
        if self.path == "/api/health":
            self._json(200, {"ready": LENS.is_file() and RULES.is_file()})
            return
        if self.path != "/":
            self._json(404, {"error": "Not found."})
            return
        page = HTML.read_text(encoding="utf-8").replace("__GUI_TOKEN__", self.server.token)
        self._send(200, page.encode("utf-8"), "text/html; charset=utf-8")

    def do_POST(self) -> None:
        if not self._local_request():
            self._json(403, {"error": "Local requests only."})
            return
        if self.path != "/api/scan":
            self._json(404, {"error": "Not found."})
            return
        if self.headers.get("X-Lens-GUI") != self.server.token:
            self._json(403, {"error": "Request token is missing or invalid. Reload the page and try again."})
            return

        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            length = 0
        if not 0 < length <= MAX_UPLOAD_BYTES + 65_536:
            self._json(413, {"error": "Choose a source file no larger than 1 MB."})
            return

        content_type = self.headers.get("Content-Type", "")
        if not content_type.lower().startswith("multipart/form-data;"):
            self._json(400, {"error": "Upload a source file using the file picker."})
            return
        try:
            body = self.rfile.read(length)
            message = BytesParser(policy=policy.default).parsebytes(
                f"Content-Type: {content_type}\r\nMIME-Version: 1.0\r\n\r\n".encode("ascii") + body
            )
            upload = next(
                part for part in message.iter_parts()
                if part.get_content_disposition() == "form-data"
                and part.get_param("name", header="content-disposition") == "file"
            )
            filename = Path(upload.get_filename() or "").name
            source = upload.get_payload(decode=True) or b""
        except (StopIteration, ValueError, TypeError, AttributeError):
            self._json(400, {"error": "The upload did not contain a readable source file."})
            return

        suffix = Path(filename).suffix.lower()
        if suffix not in ALLOWED_EXTENSIONS:
            self._json(415, {"error": "That file type is not supported. Choose a source-code file."})
            return
        if not source or len(source) > MAX_UPLOAD_BYTES:
            self._json(413, {"error": "Choose a non-empty source file no larger than 1 MB."})
            return
        if b"\0" in source:
            self._json(415, {"error": "The selected file appears to be binary. Choose a text source file."})
            return
        if not LENS.is_file() or not RULES.is_file():
            self._json(503, {"error": "The local Lens scanner is not set up. See gui/README.md."})
            return
        if not self.server.scan_lock.acquire(blocking=False):
            self._json(409, {"error": "A scan is already running. Wait for it to finish."})
            return

        try:
            with tempfile.TemporaryDirectory(prefix="lens-upload-") as temp_dir:
                target = Path(temp_dir) / f"source{suffix}"
                target.write_bytes(source)
                command = [
                    str(LENS), "--legacy", "scan", "--json", "--metrics", "off",
                    "--config", str(RULES), "--", str(target),
                ]
                try:
                    completed = subprocess.run(
                        command,
                        cwd=ROOT,
                        capture_output=True,
                        text=True,
                        encoding="utf-8",
                        errors="replace",
                        timeout=SCAN_TIMEOUT_SECONDS,
                        check=False,
                    )
                except subprocess.TimeoutExpired:
                    self._json(504, {"error": "The scan exceeded the 2-minute limit."})
                    return

                try:
                    report = json.loads(completed.stdout)
                except json.JSONDecodeError:
                    detail = (completed.stderr or completed.stdout or "Lens returned no details.")[-8_000:]
                    self._json(500, {"error": detail})
                    return

                findings = report.get("results", [])
                # Hide the temporary filesystem path from the response.
                for finding in findings:
                    finding["path"] = filename
                self._json(
                    200,
                    {
                        "findings": findings[:MAX_RESULTS],
                        "count": len(findings),
                        "truncated": len(findings) > MAX_RESULTS,
                        "errors": report.get("errors", []),
                        "engine": report.get("engine_requested"),
                        "exitCode": completed.returncode,
                    },
                )
        finally:
            self.server.scan_lock.release()


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the local Lens upload-and-scan interface.")
    parser.add_argument("--host", default="127.0.0.1", help="Interface address (defaults to local machine only).")
    parser.add_argument("--port", type=int, default=8765, help="Port to listen on (defaults to 8765).")
    parser.add_argument("--no-open", action="store_true", help="Do not open the browser automatically.")
    args = parser.parse_args()

    server = LensGuiServer((args.host, args.port), secrets.token_urlsafe(24))
    _, port = server.server_address[:2]
    url = f"http://127.0.0.1:{port}/"
    print(f"Lens is ready at {url}")
    print("Uploaded files are scanned locally and removed after each scan.")
    print("Press Ctrl+C to stop the local server.")
    if not args.no_open:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping Lens.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
