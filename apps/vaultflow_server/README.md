# vaultflow_server

Dart Frog API for VaultFlow: authentication, two-way sync with conflict detection, and resumable chunked uploads/downloads.

```bash
# from repo root
docker compose up -d postgres minio
cd apps/vaultflow_server
dart_frog dev            # http://localhost:8080/health
dart test
```

Migrations live in `migrations/` and are applied with `dart run bin/migrate.dart` (added in Phase 3).
