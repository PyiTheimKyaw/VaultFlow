# Operations

How to run, observe, back up and recover a VaultFlow deployment.

## Run in production

```bash
cp .env.example .env            # set JWT_SECRET, POSTGRES_PASSWORD, S3_SECRET_KEY, CORS_ALLOWED_ORIGINS
docker compose --profile api up -d --build
docker compose --profile api ps  # api reports healthy once /health answers
```

The `api` service runs migrations on start, stores files in MinIO
(`STORAGE_BACKEND=s3`), listens on `API_PORT` (8080) and restarts unless
stopped. Put a TLS-terminating reverse proxy (Caddy, nginx, a cloud load
balancer) in front and set `TRUST_PROXY=true` so rate limits key on the
real client address from `X-Forwarded-For`.

Required settings: `JWT_SECRET` (32+ random bytes; rotating it signs every
device out), `CORS_ALLOWED_ORIGINS` (the exact web origin, never `*` in
production).

## Limits and abuse controls

| Setting | Default | Effect |
|---|---|---|
| `RATE_LIMIT_PER_MINUTE` | 600 | per user (or IP before login); 429 + `Retry-After` |
| `AUTH_RATE_LIMIT_PER_MINUTE` | 20 | per IP on `/auth/*` |
| `MAX_JSON_BODY_BYTES` | 1 MiB | 413 before parsing |
| `MAX_CHUNK_SIZE` | 8 MiB | chunk PUT bodies and declared chunk size |
| `MAX_UPLOAD_BYTES` | 10 GiB | declared file size |
| `DOWNLOAD_LINK_TTL_MINUTES` | 5 | signed browser links |
| `EVENTS_MAX_AGE_MINUTES` | 5 | SSE connection lifetime |
| `SHUTDOWN_GRACE_SECONDS` | 20 | in-flight requests after SIGTERM |

Rate limits are per process; behind several replicas multiply accordingly
or move limiting into the proxy.

## Observability

* **Logs**: `LOG_FORMAT=json` emits one JSON object per line
  (`ts, level, tag, msg, fields`). Every response carries `X-Request-Id`;
  pass one in to correlate with client logs.
* **Metrics**: set `METRICS_TOKEN` and scrape `GET /metrics` with
  `Authorization: Bearer <token>`. Prometheus text format:
  `vaultflow_http_requests_total{method,route,status}`,
  `vaultflow_http_request_seconds_{sum,count}{method,route}`,
  `vaultflow_sync_ops_applied_total`, `vaultflow_sync_conflicts_total`,
  `vaultflow_sync_ops_rejected_total`, `vaultflow_uploads_completed_total`,
  `vaultflow_upload_bytes_total`.
* **Errors**: set `SENTRY_DSN` (and `SENTRY_ENVIRONMENT`) to report
  unhandled server errors. The app reports crashes when built with
  `SENTRY_DSN` in its env file. Neither sends user content.
* **Health**: `GET /health` → `{status, version, time}`; compose uses it as
  the container health check.
* **Client diagnostics**: Settings › Diagnostics shows build, sync and
  transfer state and the recent log tail with a "Copy report" button.

## Shutdown and upgrades

`docker compose --profile api up -d --build` performs a rolling restart:
the old container gets SIGTERM, stops accepting, finishes in-flight
requests within `SHUTDOWN_GRACE_SECONDS`, closes the pool and exits 0.
Clients retry with backoff, and uploads resume from the last acknowledged
chunk. Run migrations before deploying a server that needs them (the
container does this on start; they are additive and idempotent).

## Backups

**Postgres** (metadata, change log, upload sessions, blob index):

```bash
docker compose exec postgres pg_dump -U vaultflow -Fc vaultflow > backup-$(date +%F).dump
docker compose exec -T postgres pg_restore -U vaultflow -d vaultflow --clean --if-exists < backup-2026-09-11.dump
```

**MinIO** (file content, content-addressed under `u/<user>/<sha[0:2]>/<sha>`):

```bash
docker run --rm --network host --entrypoint sh minio/mc:latest -c \
  "mc alias set l http://localhost:9000 vaultflow vaultflow-secret && mc mirror l/vaultflow /backup/vaultflow"
```

Restore by mirroring back. Objects are immutable and keyed by hash, so a
backup can never be "wrong version"; the database decides which keys are
referenced (`blobs`). Back up the database *after* the bucket so every
referenced key exists in the object backup. `.uploads/` prefixes are
in-progress parts and can be skipped.

**Local storage backend** (`STORAGE_BACKEND=local`): back up `STORAGE_ROOT`
with the same ordering rule.

## Recovery drills

* Lost object storage: restore the bucket, then `pg_restore`. Clients with
  local copies re-upload nothing (dedupe by hash); documents whose blob is
  missing return 404 on download and can be re-imported.
* Lost database: restore `pg_dump`; clients whose `pull_cursor` is beyond
  the restored change log receive nothing new until they sign out and in
  (the cursor resets). Uploads in flight restart (session 404 → new session).
* Leaked `JWT_SECRET`: rotate it; every access and refresh token is invalid
  at once and users sign in again.
