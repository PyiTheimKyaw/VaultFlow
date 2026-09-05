#!/usr/bin/env bash
# The same gate CI runs: format, analyze, and every test suite.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "▶ dart format"
dart format --set-exit-if-changed apps packages

echo "▶ dart analyze"
dart analyze --fatal-infos .

echo "▶ pure-Dart package tests"
for dir in packages/vf_core packages/vf_protocol packages/vf_domain apps/vaultflow_server; do
  if [ -d "$dir/test" ]; then echo "  • $dir"; (cd "$dir" && dart test --reporter compact); fi
done

echo "▶ Flutter package tests"
for dir in packages/vf_database packages/vf_network packages/vf_security packages/vf_sync packages/vf_transfer packages/vf_ui apps/vaultflow_app; do
  if [ -d "$dir/test" ]; then echo "  • $dir"; (cd "$dir" && flutter test --reporter compact); fi
done

echo "✔ all checks passed"
