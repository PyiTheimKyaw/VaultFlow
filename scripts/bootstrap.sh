#!/usr/bin/env bash
# One-time developer setup: resolve the workspace, start local infra, apply migrations.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

[ -f .env ] || cp .env.example .env

echo "▶ flutter pub get (workspace)"
flutter pub get

if ! command -v dart_frog >/dev/null 2>&1; then
  echo "▶ installing dart_frog_cli"
  dart pub global activate dart_frog_cli
fi

if command -v docker >/dev/null 2>&1; then
  echo "▶ starting postgres + minio"
  docker compose up -d postgres minio minio-init
  if [ -f apps/vaultflow_server/bin/migrate.dart ]; then
    echo "▶ applying migrations"
    (cd apps/vaultflow_server && dart run bin/migrate.dart)
  fi
else
  echo "! docker not found — skipping infra (server work needs it)"
fi

echo "✔ bootstrap complete"
