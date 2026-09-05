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
(cd apps/vaultflow_server && dart_frog dev) # API on http://localhost:8080
(cd apps/vaultflow_app && flutter run -d macos)   # or -d chrome / an Android / iOS device
scripts/check.sh                           # format + analyze + all tests (same as CI)
```

The roadmap and phase checklist live in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).
