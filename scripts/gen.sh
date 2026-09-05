#!/usr/bin/env bash
# Run build_runner in every workspace member that declares it.
# Usage: scripts/gen.sh [build|watch]   (default: build)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-build}"

for dir in "$ROOT"/packages/* "$ROOT"/apps/*; do
  [ -f "$dir/pubspec.yaml" ] || continue
  if grep -q "build_runner" "$dir/pubspec.yaml"; then
    echo "▶ build_runner $MODE: ${dir#$ROOT/}"
    (cd "$dir" && dart run build_runner "$MODE" --delete-conflicting-outputs)
  fi
done
