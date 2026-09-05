# VaultFlow — Architectural Blueprint & Phased Roadmap

## Context

VaultFlow is a production-grade personal cloud vault and workspace: folders, documents (files) and notes that work fully offline, sync two-way with conflict handling, move large files with resumable chunked transfers, lock behind biometrics, and run on Android, iOS, macOS, Windows and Web from one codebase.

Current repo state: a bare `flutter create` scaffold (Flutter 3.47.1 / Dart 3.13.1, all platform folders present, `lib/main.dart` is the counter demo). No architecture exists yet, so this plan defines everything from scratch.

Decisions already made with the user:

| Decision | Choice |
|---|---|
| Backend | Self-hosted **Dart** server (dart_frog) + Postgres + S3-compatible object storage (MinIO in dev) |
| Encryption scope | **Device-secured**: Keychain/Keystore for secrets, SQLCipher local DB, TLS in transit. Server can read content. |
| Conflict strategy | **Per-entity version + "Conflicted copy"** with a resolver UI (no CRDT) |
| State management | **Riverpod 3** with code generation |

Working assumptions (change any before Phase 0 if wrong):
- One account per user, many devices. Email + password auth, rotating refresh tokens. No sharing between users in v1.
- Notes are Markdown/plain text stored in the DB. Documents are opaque binary files stored in object storage.
- Files can be multi-GB; chunk size 5 MiB (S3 multipart minimum).
- Dev machine is macOS; Docker Desktop available for Postgres + MinIO.

---

## 1. Technical Stack

### Client (Flutter)
| Concern | Choice | Why |
|---|---|---|
| Framework | Flutter 3.47 / Dart 3.13, **pub workspaces** (native monorepo, no melos needed) | Single `pub get`, shared lockfile, path deps resolved automatically |
| State / DI | `riverpod` 3 + `riverpod_annotation` + `riverpod_generator`, `freezed`, `json_serializable` | Compile-safe DI, `AsyncNotifier` + Drift streams fit offline-first |
| Local DB | `drift` (+ `drift_flutter`); SQLCipher on native; `drift` wasm + `sqlite3.wasm` on web. ⚠ `sqlite3_flutter_libs` / `sqlcipher_flutter_libs` are marked EOL on pub.dev (Sep 2026) — Phase 2 must use the current `sqlite3` native-assets route and confirm the SQLCipher option before committing to it | Only mature Flutter DB with real web support, typed SQL, migrations, FTS5, reactive queries |
| Network | `dio` (interceptors, `CancelToken`, byte streams, progress), `connectivity_plus` | Needed for range requests, streaming chunk bodies, single-flight token refresh |
| Routing | `go_router` (ShellRoute + redirect guards), `usePathUrlStrategy()` on web | URL routing, deep links, auth/lock guards |
| Security | `flutter_secure_storage`, `local_auth` (+ `local_auth_darwin` for macOS), `crypto`, `cryptography` (Argon2id/PBKDF2 for PIN) | Keychain / Keystore / DPAPI-backed secrets, biometric gate |
| Background | `workmanager` (Android/iOS periodic sync); in-process timers on desktop; foreground-only on web | Best-effort platform parity |
| Files & DnD | `file_picker` (streams on web), `path_provider`, `desktop_drop` (OS → app drops on desktop/web), Flutter `Draggable`/`DragTarget` (in-app moves) | No Rust toolchain requirement (avoids `super_native_extensions`) |
| Desktop | `window_manager` (min size, title), `Shortcuts`/`Actions` for keyboard | Desktop-grade UX |
| Lint / test | `very_good_analysis`, `mocktail`, `drift` in-memory DB, `golden_toolkit`-style goldens for breakpoints, `integration_test` | |

### Backend (Dart)
| Concern | Choice |
|---|---|
| HTTP | `dart_frog` (file-based routing, middleware, hot reload) |
| DB | Postgres 16 via `postgres` v3; plain SQL migrations run by a small `bin/migrate.dart` |
| Object storage | S3 API via `minio` Dart package (MinIO dev / any S3 in prod). `StorageAdapter` interface with `LocalFsStorage` fallback for tests |
| Auth | Argon2id password hashes, JWT access tokens (15 min) via `dart_jsonwebtoken`, opaque rotating refresh tokens (30 d, hashed at rest) |
| Infra | `docker-compose.yml` (postgres, minio, api), multi-stage Dockerfile for the API |

### Shared
`vf_protocol` package (pure Dart, freezed DTOs + error codes + route constants) is depended on by **both** the app and the server, so the wire contract cannot drift.

---

## 2. Monorepo Directory Structure

Phase 0 moves the current Flutter app from the repo root into `apps/vaultflow_app/` (`git mv` of `lib/`, `test/`, platform folders, `pubspec.yaml`, `analysis_options.yaml`), and the root becomes the workspace.

```
VaultFlow/
├── pubspec.yaml                  # workspace root: `workspace:` lists every package below
├── analysis_options.yaml         # very_good_analysis, shared
├── docker-compose.yml            # postgres + minio + api
├── .github/workflows/ci.yml      # analyze + test (app, packages, server)
├── scripts/                      # bootstrap.sh, gen.sh (build_runner all), migrate.sh
├── docs/                         # ADRs, protocol.md, schema.md (this plan feeds these)
│
├── apps/
│   ├── vaultflow_app/            # Flutter app (thin composition layer)
│   │   ├── lib/
│   │   │   ├── main.dart                     # bootstrap: ProviderScope, DB open, lock gate
│   │   │   ├── app/                          # router.dart, app.dart, di overrides
│   │   │   └── features/                     # one folder per feature, 3 layers each
│   │   │       ├── auth/        {data, application, presentation}
│   │   │       ├── lock/        # lock screen, PIN setup, biometric prompt
│   │   │       ├── vault/       # folder tree, file grid/list, breadcrumbs, DnD
│   │   │       ├── notes/       # note list + Markdown editor
│   │   │       ├── transfers/   # transfer queue UI, progress, pause/resume
│   │   │       ├── conflicts/   # conflict resolver UI
│   │   │       └── settings/    # lock timeout, biometrics toggle, storage usage
│   │   ├── android/ ios/ macos/ windows/ linux/ web/
│   │   └── test/ integration_test/
│   │
│   └── vaultflow_server/         # dart_frog
│       ├── routes/
│       │   ├── _middleware.dart              # request id, logging, error mapping
│       │   ├── health.dart
│       │   ├── auth/  {register,login,refresh,logout}.dart
│       │   ├── sync/  {push,changes,events}.dart
│       │   ├── uploads/ index.dart, [id]/{index,complete}.dart, [id]/chunks/[index].dart
│       │   └── documents/[id]/content.dart   # ranged download
│       ├── lib/
│       │   ├── auth/          # password hashing, jwt, refresh rotation
│       │   ├── sync/          # SyncService: apply op, version check, change log
│       │   ├── storage/       # StorageAdapter, S3Storage, LocalFsStorage
│       │   ├── transfer/      # UploadSessionService
│       │   └── db/            # Postgres pool, repositories
│       ├── migrations/        # 0001_init.sql, 0002_... (plain SQL)
│       ├── bin/migrate.dart
│       ├── test/
│       └── Dockerfile
│
└── packages/
    ├── vf_core/          # Result<T>/Failure, Uuid v7 ids, Clock, Logger, extensions — zero Flutter deps
    ├── vf_protocol/      # shared DTOs, enums (EntityType, SyncOp, TransferState), error codes, API paths
    ├── vf_domain/        # entities (Folder, Document, Note, Conflict), repository interfaces, use cases
    ├── vf_database/      # Drift schema, DAOs, migrations, SQLCipher/wasm openers, FTS5
    ├── vf_network/       # Dio factory, AuthInterceptor (single-flight refresh), ConnectivityMonitor, ApiClient
    ├── vf_sync/          # SyncEngine: OutboxProcessor, ChangePuller, ConflictDetector, SyncScheduler
    ├── vf_transfer/      # TransferEngine: UploadWorker, DownloadWorker, ChunkPlanner, Hasher (isolate)
    ├── vf_security/      # SecureStore, BiometricGate, AppLockController, PinVault, DbKeyProvider
    └── vf_ui/            # design tokens, ThemeData, Breakpoints, AdaptiveScaffold, shared widgets
```

Dependency direction (enforced by pubspec, no cycles):
`vf_core ← vf_protocol ← vf_domain ← {vf_database, vf_network, vf_security} ← {vf_sync, vf_transfer} ← app`. `vf_ui` depends only on `vf_core`. Server depends on `vf_core` + `vf_protocol` only.

---

## 3. Data Model & Schemas

### 3.1 Client local schema (Drift / SQLite, SQLCipher on native)

Common columns on every synced entity: `id TEXT PK` (UUID v7, generated client-side so offline creates need no server round-trip), `version INTEGER` (server-authoritative, 0 = never synced), `created_at`, `updated_at`, `deleted_at` (soft delete / tombstone), `sync_status` (`synced | pending | conflicted`).

```sql
folders    (id, parent_id NULL→folders.id, name, version, created_at, updated_at, deleted_at, sync_status)
documents  (id, folder_id→folders.id, name, mime_type, size_bytes, sha256,
            storage_key NULL,          -- server object key once uploaded
            local_path NULL,           -- cached file on disk
            cache_state,               -- none | partial | complete
            version, created_at, updated_at, deleted_at, sync_status)
notes      (id, folder_id→folders.id, title, body, version, created_at, updated_at, deleted_at, sync_status)
notes_fts  (FTS5 virtual table over notes.title, notes.body; triggers keep it in sync)

conflicts  (id, entity_type, entity_id, local_snapshot JSON, remote_snapshot JSON,
            remote_version, created_at, resolved_at NULL, resolution NULL)  -- keep_local | keep_remote | keep_both

-- Sync queue (outbox)
sync_outbox (id INTEGER PK AUTOINCREMENT,      -- FIFO order
             client_op_id TEXT UNIQUE,          -- UUID, idempotency key on server
             entity_type, entity_id,
             op,                                -- create | update | delete | move
             payload JSON,                      -- full entity snapshot for create/update; {folder_id} for move
             base_version INTEGER,              -- version the edit was made against
             state,                             -- pending | in_flight | failed | blocked
             depends_on_transfer NULL→transfer_sessions.id,  -- doc create waits for upload
             attempt_count, next_attempt_at, last_error, created_at)

sync_state  (key TEXT PK, value TEXT)           -- pull_cursor, device_id, last_sync_at

-- Resumable transfers
transfer_sessions (id TEXT PK, kind,            -- upload | download
                   document_id→documents.id,
                   remote_session_id NULL,      -- server upload_id
                   local_path, total_bytes, chunk_size, sha256_expected NULL,
                   state,                       -- queued | running | paused | failed | completed | cancelled
                   bytes_done, attempt_count, last_error, created_at, updated_at)
transfer_chunks   (session_id→transfer_sessions.id, idx INTEGER, offset, length,
                   state,                       -- pending | done
                   etag NULL, PRIMARY KEY(session_id, idx))

app_settings (key TEXT PK, value TEXT)          -- lock_timeout_s, biometrics_enabled, theme
```

Outbox coalescing rules (applied on enqueue when a `pending` row for the same entity exists):
`create+update → create(merged)`, `update+update → update(latest)`, `create+delete → drop both`, `update+delete → delete`. `in_flight` rows are never merged.

### 3.2 Server schema (Postgres)

```sql
users           (id UUID PK, email CITEXT UNIQUE, password_hash, created_at)
devices         (id UUID PK, user_id→users, name, platform, last_seen_at)
refresh_tokens  (id UUID PK, user_id, device_id, token_hash, expires_at, revoked_at, replaced_by NULL)

folders / documents / notes  -- same columns as client + user_id, NOT NULL version, tombstones kept
blobs           (storage_key PK, user_id, size_bytes, sha256, ref_count, created_at)   -- dedupe by (user_id, sha256)

changes         (seq BIGSERIAL PK, user_id, device_id, entity_type, entity_id, op, version,
                 payload JSONB, created_at)      -- append-only feed; INDEX (user_id, seq)
applied_ops     (device_id, client_op_id, result JSONB, PRIMARY KEY(device_id, client_op_id))  -- idempotent push

upload_sessions (id UUID PK, user_id, document_id, storage_key, s3_upload_id, total_bytes, chunk_size,
                 sha256_expected, received_chunks INT[] , state, expires_at, created_at)
```

---

## 4. Protocols

### 4.1 Sync protocol (offline-first, two-way)

**Push** — `POST /sync/push` `{device_id, ops:[{client_op_id, entity_type, entity_id, op, base_version, payload}]}`
Server, per op inside one transaction:
1. If `(device_id, client_op_id)` in `applied_ops` → return stored result (idempotent retry).
2. Load current row. If missing and op≠create → `rejected`. If `current.version != base_version` → **`conflict`** with `remote` snapshot + `remote_version`.
3. Else apply, `version = version + 1`, append to `changes`, return `applied {new_version}`.

Client `OutboxProcessor`: FIFO, batches of ≤100 ops, exponential backoff (1s→5min, jitter) on network failure, marks `failed` after 10 attempts (surfaced in UI, never silently dropped). On `applied` → write `version`, `sync_status=synced`, delete outbox row. On `conflict` → write a `conflicts` row, set entity `sync_status=conflicted`, delete outbox row. On `rejected` → log, drop row, mark entity for re-pull.

**Pull** — `GET /sync/changes?since={cursor}&limit=500&exclude_device={device_id}` → `{changes:[...], next_cursor, has_more}`.
Client `ChangePuller` applies each change: if the entity has a `pending`/`in_flight` outbox row → skip (the push will detect the conflict authoritatively); else upsert/tombstone locally with `sync_status=synced`. Persist `pull_cursor` after each page.

**Conflict resolution UX**: entity shows a badge; resolver offers *Keep mine* (re-enqueue as update with `base_version=remote_version`), *Keep theirs* (overwrite local), *Keep both* (theirs replaces local; mine becomes `"<name> (Conflicted copy, <device>, <date>)"` as a new create).

**Triggers** (`SyncScheduler`): app start, connectivity regained, local mutation (debounced 2s), app resumed, every 15 min (workmanager on mobile, `Timer` on desktop), and optional SSE nudge `GET /sync/events` (Phase 6).

**Ordering guarantees**: FIFO outbox naturally creates parents before children. Document `create` ops carry `depends_on_transfer` and stay `blocked` until the upload session completes and fills `storage_key`.

### 4.2 Resumable chunked transfer protocol

**Upload**
1. `POST /uploads` `{document_id, total_bytes, sha256, mime_type, chunk_size:5MiB}` → `{upload_id, chunk_size, expires_at}` or `{dedup:true, storage_key}` when `(user_id, sha256)` already exists (instant upload).
2. `PUT /uploads/{id}/chunks/{idx}` raw bytes, `Content-Length`, `X-Chunk-Sha256`. Server → S3 `UploadPart` (or local part file), appends `idx` to `received_chunks`. Idempotent. Up to **3 chunks in parallel** per session.
3. `GET /uploads/{id}` → `{received_chunks, expires_at}`. Client calls this on every resume (app restart, network back) and reconciles `transfer_chunks` before continuing — **never restarts from zero**.
4. `POST /uploads/{id}/complete` → server `CompleteMultipartUpload`, verifies size + sha256 (streamed re-hash for local storage; ETag/part hashes for S3), inserts `blobs`, sets `documents.storage_key`, bumps version, appends `changes`. Returns `{version, storage_key}`. Unblocks the outbox `create`.
Expired sessions (24 h) are GC'd server-side; the client starts a new session if `GET` returns 404.

**Download**
`GET /documents/{id}/content` with `Range: bytes={bytes_done}-`; server returns `206`, `Accept-Ranges`, `ETag=sha256`. Client appends to `<name>.part` at the offset, updates `bytes_done` every 1 MiB, verifies sha256 at the end (in an isolate), renames to the final path, sets `cache_state=complete`. If the `ETag` changes mid-way, restart that file.

**Engine**: `TransferEngine` owns a bounded worker pool (2 concurrent sessions), each with a `CancelToken` for pause/cancel; state is persisted in `transfer_sessions`/`transfer_chunks` so a killed app resumes exactly where it stopped. Progress is a Drift stream consumed by the UI.

### 4.3 Auth
`POST /auth/register`, `/auth/login` → `{access_token, refresh_token, device_id}`. `POST /auth/refresh` rotates the refresh token (old one `replaced_by`, reuse of a rotated token revokes the whole chain). `AuthInterceptor` (dio `QueuedInterceptor`) attaches the access token, and on 401 performs exactly one refresh for all queued requests, then replays.

---

## 5. Security Model (device-secured)

- **Secrets**: access/refresh tokens, device id, DB key, PIN hash → `SecureStore` (flutter_secure_storage: iOS/macOS Keychain, Android Keystore-backed EncryptedSharedPreferences, Windows DPAPI, Linux libsecret). Web: WebCrypto-wrapped localStorage (documented as weaker; tokens are short-lived).
- **DB at rest**: 32 random bytes generated on first launch → secure storage → `PRAGMA key` for SQLCipher via Drift `NativeDatabase`. Web has no SQLCipher; relies on origin isolation (documented limitation).
- **App lock**: `AppLockController` (Riverpod notifier) listens to `AppLifecycleListener`. On `hidden`/`paused` it stores the timestamp; on `resumed` it locks if `elapsed ≥ lock_timeout` (default: immediately). A lock overlay sits *above* the router (`Stack` in `App`) so it covers every route and survives navigation. Unlock via `local_auth.authenticate(biometricOnly:false)` with **PIN fallback** (Argon2id-hashed, stored in secure storage, 5-attempt backoff). Web/Linux: PIN only.
- **Privacy**: on `inactive`, render a blur/cover so the OS app switcher snapshot is blank.
- **Transport**: HTTPS only, optional certificate pinning hook in `DioFactory` for production.
- **Cached files** live in the app's sandboxed documents dir; "Clear local cache" and "Log out" wipe files, DB, and secure storage.

---

## 6. Adaptive UI Rules

| Width | Layout |
|---|---|
| < 600 (compact) | Bottom `NavigationBar`, full-screen pages, folder tree as a drawer |
| 600–840 (medium) | `NavigationRail`, single content pane |
| > 840 (expanded) | Persistent, resizable **sidebar** (folder tree), content pane, optional detail/preview pane |

- `AdaptiveScaffold` in `vf_ui` implements the table using `LayoutBuilder`; `Breakpoints` are the single source of truth.
- Routes: `/login`, `/vault` , `/vault/:folderId`, `/notes/:noteId`, `/transfers`, `/settings`; `redirect` guard sends unauthenticated users to `/login`. Lock is an overlay, not a route, so the URL is preserved on web.
- Drag & drop: `desktop_drop` for OS files dropped onto a folder (desktop + web); `LongPressDraggable`/`Draggable` + `DragTarget` for moving items between folders in-app (mobile uses long-press, desktop uses mouse drag).
- Desktop extras: right-click context menus, `Shortcuts` (⌘N new note, ⌘⇧N new folder, Del, F2 rename, ⌘F search), `window_manager` minimum size 800×600.
- Platform capability matrix documented in `docs/platforms.md` (biometrics, background sync, SQLCipher, OS drag-drop, ranged downloads to disk are all unavailable or degraded on web).

---

## 7. Phased Implementation Checklist

Each phase ends with a green `dart analyze`, green tests, and a runnable app. Execute one phase per session.

### Phase 0 — Monorepo & tooling foundation
- [x] `git mv` current Flutter app into `apps/vaultflow_app/`; fix `.idea`, verify `flutter run -d macos` still works
- [x] Root `pubspec.yaml` with `workspace:`; every package/app gets `resolution: workspace`
- [x] Create empty packages `vf_core, vf_protocol, vf_domain, vf_database, vf_network, vf_sync, vf_transfer, vf_security, vf_ui` (`dart create -t package`), wire dependency graph
- [x] Scaffold `apps/vaultflow_server` with `dart_frog create`, `/health` route
- [x] `docker-compose.yml` (postgres:16, minio), `.env.example`, `scripts/bootstrap.sh`, `scripts/gen.sh`
- [x] Shared `analysis_options.yaml` (very_good_analysis), `.github/workflows/ci.yml` (analyze + test matrix)
- [x] `docs/adr/0001-stack.md` recording the decisions above
- **Exit**: `dart pub get` at root resolves everything; CI green; app + server run.
- **Done 2026-09-05.** Notes: root `flutter pub get` is required (workspace contains Flutter members); `scripts/check.sh` mirrors CI; `dart_frog dev` verified with `/health`.

### Phase 1 — Core packages, design system, app shell
- [ ] `vf_core`: `Result<T>`/`Failure` hierarchy, `Uuid.v7()`, `Clock`, `Logger`
- [ ] `vf_protocol`: freezed DTOs for Folder/Document/Note, `SyncOp`, `EntityType`, `PushRequest/Response`, `ChangesResponse`, `UploadSession*`, `ApiErrorCode`, `ApiPaths`
- [ ] `vf_ui`: color/typography tokens, light/dark `ThemeData`, `Breakpoints`, `AdaptiveScaffold`, `EmptyState`, `SyncStatusBadge`
- [ ] App: `ProviderScope`, `go_router` with ShellRoute + placeholder pages for all routes, `usePathUrlStrategy()` on web, `window_manager` on desktop
- [ ] Golden tests for `AdaptiveScaffold` at 400/700/1200 px
- **Exit**: navigable shell on phone, desktop and web with correct layouts and URLs.

### Phase 2 — Local database & fully offline CRUD
- [ ] `vf_database`: Drift tables from §3.1, DAOs (`FoldersDao`, `DocumentsDao`, `NotesDao`, `OutboxDao`, `TransfersDao`, `ConflictsDao`), FTS5 for notes, migration strategy, `openDatabase()` per platform (SQLCipher native / wasm web)
- [ ] `vf_security.DbKeyProvider` (random key → secure storage) — minimal slice needed by the DB opener
- [ ] `vf_domain`: entities, `VaultRepository`, `NotesRepository` interfaces, use cases (`CreateFolder`, `MoveItem`, `RenameItem`, `SoftDelete`, `SaveNote`…)
- [ ] Repository impls in `vf_database` write entity + **outbox row in one transaction** (coalescing rules)
- [ ] Features `vault` (tree, list/grid, breadcrumb, create/rename/move/delete, import file via `file_picker` → copies to cache dir, `cache_state=complete`) and `notes` (list + Markdown editor with autosave)
- [ ] Tests: DAO tests on in-memory Drift, coalescing rules, use-case tests with fakes
- **Exit**: full CRUD works with no network; outbox fills up correctly (inspectable in a debug screen).

### Phase 3 — Auth, network client, vault lock
- [ ] Server: migrations `0001_init.sql` (users, devices, refresh_tokens), `/auth/*` routes, Argon2id, JWT, refresh rotation + reuse detection, auth middleware, request-id/error middleware
- [ ] `vf_network`: `DioFactory`, `AuthInterceptor` (single-flight refresh), `ConnectivityMonitor` stream, `ApiClient` typed over `vf_protocol`
- [ ] `vf_security`: `SecureStore`, `BiometricGate`, `PinVault`, `AppLockController` + lifecycle hooks, privacy cover
- [ ] Features `auth` (login/register, session restore), `lock` (lock overlay, biometric prompt, PIN setup/fallback), `settings` (lock timeout, biometrics toggle, logout = wipe)
- [ ] Tests: server auth integration tests (Postgres in Docker), interceptor refresh single-flight test, `AppLockController` tests with fake clock
- **Exit**: log in on device, background the app, return → biometric lock; token refresh transparent.

### Phase 4 — Sync engine & conflict resolution
- [ ] Server: migrations for folders/documents/notes/changes/applied_ops; `SyncService.applyOps` (version check, change log, idempotency); `/sync/push`, `/sync/changes`
- [ ] `vf_sync`: `OutboxProcessor` (FIFO, batching, backoff, `blocked` handling), `ChangePuller` (cursor paging, skip-if-pending), `ConflictDetector` → `conflicts` table, `SyncScheduler` (triggers in §4.1), `workmanager` periodic task on mobile
- [ ] Feature `conflicts`: badge, resolver sheet (keep mine / theirs / both), sync status indicator in app bar, "Sync now"
- [ ] Tests: server conflict/idempotency tests; client sync tests against an in-process fake server; **two-device simulation test** (two DBs, one server, edit same note offline on both, reconnect → exactly one conflict)
- **Exit**: edits made offline on two devices converge; conflicts are visible and resolvable.

### Phase 5 — Resumable large-file transfers
- [ ] Server: `StorageAdapter` (`S3Storage` via MinIO, `LocalFsStorage`), `upload_sessions` migration, `/uploads*` routes, sha256 verification, blob dedupe, ranged `/documents/{id}/content` (206, ETag), expired-session GC
- [ ] `vf_transfer`: `ChunkPlanner`, `UploadWorker` (3 parallel chunks, reconcile via `GET /uploads/{id}`), `DownloadWorker` (Range resume, `.part` files), `Hasher` in isolate, `TransferEngine` pool + pause/resume/cancel + persistence
- [ ] Wire `depends_on_transfer` between outbox document creates and upload sessions; auto-download on open; "Make available offline" toggle
- [ ] Feature `transfers`: queue list, per-item progress/speed/ETA, pause/resume/cancel/retry, bytes-saved-by-dedupe
- [ ] Tests: fault-injecting test server (drops connection at random byte), kill-app-mid-upload integration test resumes from persisted chunk state, download resume test, hash-mismatch test
- **Exit**: a 1 GB file survives airplane-mode toggles and app kills without restarting.

### Phase 6 — Adaptive UX polish & platform integration
- [ ] Drag & drop: `desktop_drop` OS-file drops → import into target folder; in-app `Draggable`/`DragTarget` moves with drop highlighting
- [ ] Desktop: context menus, keyboard `Shortcuts`/`Actions`, resizable sidebar, multi-select
- [ ] Search (FTS5 notes + name search) with `/search?q=` route
- [ ] Web: deep-link restore, PWA manifest, downloads via short-lived signed URL (web can't write ranged `.part` files)
- [ ] Mobile: share-sheet import, pull-to-refresh sync, iOS `BGTaskScheduler`/Android foreground service for long transfers (optional, behind a flag)
- [ ] Optional SSE `/sync/events` realtime nudge
- [ ] Accessibility pass (semantics, focus order, contrast), i18n scaffolding
- **Exit**: UX parity checklist in `docs/platforms.md` fully ticked per platform.

### Phase 7 — Production hardening
- [ ] Observability: structured logs, optional Sentry (client + server), sync/transfer metrics
- [ ] Server: rate limiting, request size limits, CORS for web origin, graceful shutdown, Dockerfile + `docker compose up` prod profile, backup notes for Postgres/MinIO
- [ ] Client: crash-safe DB migrations test (upgrade from every prior schema), storage quota handling, low-disk behavior
- [ ] E2E: `integration_test` suite (login → create → sync → conflict → transfer) run in CI on macOS + Android emulator
- [ ] Release: app icons/splash, flavors (dev/staging/prod via `--dart-define`), signing docs, CHANGELOG
- [ ] Security review checklist (token lifetimes, lock bypass attempts, path traversal in storage keys, chunk-size abuse)

---

## 8. Verification Strategy (applies every phase)

```bash
# from repo root
dart pub get
dart run build_runner build -d            # via scripts/gen.sh across packages
dart analyze
dart test                                 # all pure-Dart packages
(cd apps/vaultflow_app && flutter test)
docker compose up -d postgres minio && (cd apps/vaultflow_server && dart run bin/migrate.dart && dart_frog dev)
(cd apps/vaultflow_app && flutter run -d macos)     # then -d chrome, -d <android/ios device>
```

Phase-specific acceptance tests are listed under each phase's **Exit** line; the two-device simulation (Phase 4) and the kill-and-resume transfer test (Phase 5) are the critical regression gates and stay in CI permanently.
