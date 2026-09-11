# Changelog

## 0.7.0 — 2026-09-11 (Phase 7: production hardening)

- Server: per-user/IP rate limiting with a stricter budget on `/auth/*`, bounded JSON bodies, capped upload sizes, security headers, Prometheus `/metrics` (token-gated), JSON logs, optional Sentry, graceful shutdown on SIGTERM, health reports the version.
- Storage keys neutralise `.`/`..` segments (found by the new path-traversal test).
- App: build flavors via `env/*.json`, optional Sentry crash reporting, Settings › Diagnostics (build, sync, transfers, log tail, copy report), Settings › Storage (cache usage, free up space), disk-full errors reported plainly and never retried.
- Database: schema recorded under `drift_schemas/`, migration tests from every shipped version.
- End-to-end suite (`integration_test/`) against a live API, run in CI on macOS and an Android emulator.
- Icons and splash screens for every platform; release, operations and security-review docs.

## 0.6.0 — 2026-09-09 (Phase 6)

- Drag and drop, multi-select, context menus, keyboard shortcuts, resizable sidebar, search, realtime sync events, signed web downloads, Android share-sheet import, localization scaffold.

## 0.5.0 — 2026-09-09 (Phase 5)

- Resumable chunked uploads, ranged downloads, dedupe, local and S3 storage.

## 0.4.0 (Phase 4) — two-way sync and conflict resolution.
## 0.3.0 (Phase 3) — accounts, token refresh, vault lock.
## 0.2.0 (Phase 2) — offline vault and notes.
## 0.1.0 (Phase 1) — shell, design system, routing.
