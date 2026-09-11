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

## Auth

| Route | Body | Notes |
|---|---|---|
| `POST /auth/register` | `CredentialsRequest` | 201 with `AuthTokens`; 409 `email_taken` |
| `POST /auth/login` | `CredentialsRequest` | 401 `unauthorized` for bad credentials |
| `POST /auth/refresh` | `RefreshRequest` | rotates the refresh token; replaying an old one revokes the family (`token_revoked`) |
| `POST /auth/logout` | `RefreshRequest` | 204; revokes the family |
| `GET /auth/me` | bearer access token | `{user_id, email, device_id}` |

Without `DATABASE_URL` the server uses an in-memory store (development only).
With it, run `dart run bin/migrate.dart` first. Postgres integration tests run
when `TEST_DATABASE_URL` points at a disposable database; CI provides one as a
service container and runs the migrations before the test step.

## Sync

| Route | Notes |
|---|---|
| `POST /sync/push` | `PushRequest` (≤100 ops); per op `applied {new_version}` / `conflict {remote, remote_version}` / `rejected {error}`; idempotent on `(device_id, client_op_id)` |
| `GET /sync/changes?since=&limit=&exclude_device=` | `ChangesResponse` page of the append-only feed |

Both require a bearer access token; `device_id` in the push body must match the token.

## Transfers

| Route | Notes |
|---|---|
| `POST /uploads` | `UploadSessionCreateRequest`; 201 with `upload_id` or 200 `{dedup: true, storage_key}` |
| `GET /uploads/{id}` | received chunk indexes, expiry |
| `PUT /uploads/{id}/chunks/{n}` | raw bytes, `X-Chunk-Sha256`, exact chunk length; idempotent |
| `POST /uploads/{id}/complete` | assembles, verifies sha256, registers the blob, stamps the document if it exists |
| `GET /documents/{id}/content` | bytes with `Range` support (206, `ETag` = sha256); also accepts `?token=` from a download link (served as an attachment) |
| `POST /documents/{id}/download-url` | 5-minute signed link for browsers (`DOWNLOAD_LINK_TTL_MINUTES`) |
| `GET /sync/events` | server-sent events: `event: change` with the newest seq from other devices, `: ping` every 15 s, closes after `EVENTS_MAX_AGE_MINUTES` |

Storage: `STORAGE_BACKEND=local` (default, `STORAGE_ROOT`) or `s3` with the
`S3_*` variables. Sessions expire after `UPLOAD_SESSION_TTL_HOURS`.

## Hardening

Limits, rate limiting, `GET /metrics` (`METRICS_TOKEN`), JSON logs
(`LOG_FORMAT=json`), Sentry (`SENTRY_DSN`) and graceful shutdown are
described in `docs/OPERATIONS.md`; the security controls and their tests in
`docs/SECURITY_REVIEW.md`. `main.dart` is the dart_frog custom entrypoint.
