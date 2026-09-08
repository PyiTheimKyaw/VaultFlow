#!/usr/bin/env bash
# Runs the API with hot reload on http://localhost:8080.
#
#   scripts/dev_server.sh            # in-memory store (no Postgres needed)
#   DATABASE_URL=postgres://... scripts/dev_server.sh   # Postgres, runs migrations first
#
# Reads .env from the repo root if present. Only JWT_SECRET is required;
# ARGON2_MEMORY_KIB is lowered so registering is instant on a laptop.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$ROOT/.env" ]; then set -a; . "$ROOT/.env"; set +a; fi
export JWT_SECRET="${JWT_SECRET:-dev-secret-change-me}"
export ARGON2_MEMORY_KIB="${ARGON2_MEMORY_KIB:-4096}"
export CORS_ALLOWED_ORIGINS="${CORS_ALLOWED_ORIGINS:-*}"
export DATABASE_URL="${DATABASE_URL:-}"

if ! command -v dart_frog >/dev/null 2>&1; then
  echo "▶ installing dart_frog_cli"; dart pub global activate dart_frog_cli
fi
cd "$ROOT/apps/vaultflow_server"
if [ -n "$DATABASE_URL" ]; then
  echo "▶ applying migrations to $DATABASE_URL"; dart run bin/migrate.dart
else
  echo "▶ DATABASE_URL not set: in-memory store (data is lost on restart/hot reload)"
fi
echo "▶ API on http://localhost:8080  (Ctrl+C to stop)"
exec dart_frog dev
