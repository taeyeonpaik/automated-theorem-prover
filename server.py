"""Local, standard-library-only HTTP server for the JavaScript interface."""
import argparse
import json
import subprocess
import sqlite3
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse, parse_qs

import client
import storage
import tptp
from examples import EXAMPLES

ROOT = Path(__file__).resolve().parent
TPTP_ROOT = ROOT / "benchmarks/tptp-v3.3.0"
TPTP_REPORT = ROOT / "benchmarks/results-tptp.json"
FULL_REPORT = ROOT / "benchmarks/full-tptp-9.3.1-v2"
V1_REPORT = ROOT / "benchmarks/full-tptp-9.3.1"
# Browsers need a document bootstrap; the entire interface is authored in JS.
SHELL = b'<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>QED</title><script src="/app.js" type="module"></script>'


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
        elif path == "/api/evaluation":
            if TPTP_REPORT.exists():
                report = json.loads(TPTP_REPORT.read_text())
                self.reply({k: report[k] for k in ("corpus", "complete", "repeat", "limits", "summary", "problems", "mismatches")})
            else:
                self.reply({"available": False})
        elif path == "/api/evaluation/report" and TPTP_REPORT.exists():
            self.reply(TPTP_REPORT.read_bytes())
        elif path == "/api/full-evaluation":
            summary = FULL_REPORT / "summary.json"
            report = json.loads(summary.read_text()) if summary.exists() else {"available": False}
            pipeline = FULL_REPORT / "pipeline-status.json"
            report["pipeline"] = json.loads(pipeline.read_text()) if pipeline.exists() else None
            self.reply(report)
        elif path == "/api/full-evaluation/v1" and (V1_REPORT / "summary.json").exists():
            self.reply((V1_REPORT / "summary.json").read_bytes())
        elif path == "/api/full-evaluation/v1-metrics" and (V1_REPORT / "paired-metrics.json").exists():
            self.reply((V1_REPORT / "paired-metrics.json").read_bytes())
        elif path == "/api/full-evaluation/results.csv" and (FULL_REPORT / "results.csv").exists():
            self.reply((FULL_REPORT / "results.csv").read_bytes(), "text/csv")
        elif path == "/api/full-evaluation/metrics":
            metrics = FULL_REPORT / "paired-metrics.json"
            self.reply(json.loads(metrics.read_text()) if metrics.exists() else {"available": False})
        elif path == "/api/full-tptp/problem":
            requested = parse_qs(urlparse(self.path).query).get("name", [""])[0]
            if "/" not in requested:
                requested = f"Problems/{requested[:3]}/{requested}"
                if not requested.endswith(".p"):
                    requested += ".p"
            database = FULL_REPORT / "results.sqlite3"
            if not database.exists():
                self.reply({"error": "Full evaluation has not started"}, status=404)
                return
            with sqlite3.connect(database.as_uri() + "?mode=ro", uri=True) as db:
                row = db.execute("SELECT descriptor,input FROM problems WHERE name=?", (requested,)).fetchone()
            if row is None:
                self.reply({"error": "Unknown problem, or preflight has not reached it yet"}, status=404)
            elif json.loads(row[0])["state"] != "accepted":
                self.reply({"error": json.loads(row[0])["reason"]}, status=400)
            else:
                self.reply(json.loads(row[1]))
        elif path == "/api/tptp/problem":
            requested = parse_qs(urlparse(self.path).query).get("name", [""])[0]
            if not (TPTP_ROOT / "manifest.json").exists():
                self.reply({"error": "Run python3 fetch_tptp.py first"}, status=404)
                return
            manifest = json.loads((TPTP_ROOT / "manifest.json").read_text())
            if requested not in manifest["problem_paths"]:
                self.reply({"error": "Unknown TPTP problem"}, status=404)
                return
            try:
                problem = tptp.load(TPTP_ROOT / requested, root=TPTP_ROOT)
                client.validate(problem)
                self.reply(problem)
            except (ValueError, OSError) as error:
                self.reply({"error": str(error)}, status=400)
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
