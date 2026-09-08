# VaultFlow

Production-grade personal cloud vault and workspace: offline-first folders, documents and notes with
two-way sync and conflict resolution, resumable chunked file transfers, biometric vault lock, and an
adaptive UI for Android, iOS, macOS, Windows and Web.

## Layout

```
apps/vaultflow_app      Flutter client
apps/vaultflow_server   Dart Frog API (auth, sync, transfers)
packages/vf_*           Shared packages (see docs/ARCHITECTURE.md §2)
docs/                   Architecture blueprint, ADRs
scripts/                bootstrap.sh, gen.sh, check.sh
```

## Getting started

```bash
scripts/bootstrap.sh                       # pub get, install dart_frog, start postgres + minio
scripts/dev_server.sh                      # API on http://localhost:8080 (in-memory unless DATABASE_URL is set)
scripts/serve_web.sh                       # web build on http://127.0.0.1:8765 with COOP/COEP headers
(cd apps/vaultflow_app && flutter run -d macos)   # or -d chrome / an Android / iOS device
scripts/check.sh                           # format + analyze + all tests (same as CI)
```

The roadmap and phase checklist live in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

Manual test flows per phase: [docs/MANUAL_TESTING.md](docs/MANUAL_TESTING.md).
