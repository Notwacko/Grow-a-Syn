import base64
import os
import re
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
TARGET = os.path.join(ROOT, "src", "models", "core")
NAME = re.compile(r"^/save/([A-Za-z0-9_]+)\.rbxm$")
TEXT_NAME = re.compile(r"^/text/([A-Za-z0-9_]+)\.lua$")
TEXT_TARGET = os.path.join(ROOT, "src", "client")
MAX_BYTES = 20 * 1024 * 1024


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        text_match = TEXT_NAME.match(self.path)
        if text_match and 0 < length <= MAX_BYTES:
            body = self.rfile.read(length)
            os.makedirs(TEXT_TARGET, exist_ok=True)
            with open(os.path.join(TEXT_TARGET, text_match.group(1) + ".lua"), "wb") as handle:
                handle.write(body)
            self.send_response(200)
            self.end_headers()
            self.wfile.write(str(len(body)).encode())
            return
        match = NAME.match(self.path)
        if not match or length <= 0 or length > MAX_BYTES:
            self.send_response(400)
            self.end_headers()
            return
        body = self.rfile.read(length)
        try:
            data = base64.b64decode(body, validate=True)
        except Exception:
            self.send_response(400)
            self.end_headers()
            return
        os.makedirs(TARGET, exist_ok=True)
        with open(os.path.join(TARGET, match.group(1) + ".rbxm"), "wb") as handle:
            handle.write(data)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(str(len(data)).encode())

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8766
    HTTPServer(("127.0.0.1", port), Handler).serve_forever()
