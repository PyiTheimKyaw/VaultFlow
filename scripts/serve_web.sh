#!/usr/bin/env bash
# Builds the web app and serves it on http://127.0.0.1:8765 with the
# Cross-Origin-Opener-Policy / Cross-Origin-Embedder-Policy headers that the
# browser needs for durable (OPFS) storage. `flutter run -d chrome` does not
# send those headers, so it falls back to IndexedDB, which can lose the last
# seconds of writes on reload.
#
#   scripts/serve_web.sh                       # API at http://localhost:8080
#   API=http://192.168.1.10:8080 scripts/serve_web.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API="${API:-http://localhost:8080}"
PORT="${PORT:-8765}"
cd "$ROOT/apps/vaultflow_app"
echo "▶ building web (API=$API)"
flutter build web --release --no-web-resources-cdn --dart-define=VAULTFLOW_API_BASE_URL="$API"
echo "▶ serving on http://127.0.0.1:$PORT  (Ctrl+C to stop)"
exec python3 - "$PWD/build/web" "$PORT" <<'PY'
import http.server, os, sys
ROOT = sys.argv[1]; PORT = int(sys.argv[2])
class H(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **k): super().__init__(*a, directory=ROOT, **k)
    def send_head(self):
        if not os.path.exists(self.translate_path(self.path)):
            self.path = '/index.html'          # SPA fallback for deep links
        return super().send_head()
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()
    def log_message(self, *a): pass
http.server.ThreadingHTTPServer(('127.0.0.1', PORT), H).serve_forever()
PY
