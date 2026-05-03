"""Local, standard-library-only HTTP server for the JavaScript interface."""
import argparse
import json
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

import client
import storage
from examples import EXAMPLES

ROOT = Path(__file__).resolve().parent
# Browsers need a document bootstrap; the entire interface is authored in JS.
SHELL = b'<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>QED</title><script src="/app.js" defer></script>'


class Handler(BaseHTTPRequestHandler):
    def reply(self, body, content_type="application/json", status=200):
        if not isinstance(body, bytes):
            body = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", content_type + "; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'none'; frame-ancestors 'none'")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = urlparse(self.path).path
        if path == "/":
            self.reply(SHELL, "text/html")
        elif path == "/app.js":
            self.reply((ROOT / "web/app.js").read_bytes(), "text/javascript")
        elif path == "/api/examples":
            self.reply(EXAMPLES)
        elif path == "/api/history":
            self.reply(storage.history(self.server.db_path))
        else:
            self.reply({"error": "Not found"}, status=404)

    def do_POST(self):
        if self.path != "/api/prove":
            self.reply({"error": "Not found"}, status=404)
            return
        # JSON-only requests and same-origin checking keep this local service
        # from accepting cross-site form submissions.
        if self.headers.get("Origin") not in (None, "http://" + self.headers.get("Host", "")):
            self.reply({"error": "Origin mismatch"}, status=403)
            return
        if self.headers.get("Content-Type", "").split(";")[0] != "application/json":
            self.reply({"error": "Use application/json"}, status=415)
            return
        try:
            size = int(self.headers.get("Content-Length", "0"))
            if not 0 < size <= 100000:
                raise ValueError("Invalid request size")
            problem = json.loads(self.rfile.read(size))
            result = client.run(problem)
            result["run_id"] = storage.save(result, self.server.db_path)
            self.reply(result)
        except (ValueError, TypeError, OverflowError) as error:
            self.reply({"error": str(error)}, status=400)
        except (RuntimeError, subprocess.TimeoutExpired) as error:
            self.reply({"error": str(error)}, status=500)


def create_server(port=8000, db_path=storage.DEFAULT_DB):
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    server.db_path = db_path
    return server


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8000)
    args = parser.parse_args()
    server = create_server(args.port)
    print(f"QED is ready at http://127.0.0.1:{server.server_port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        server.server_close()
