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
- [x] `vf_core`: `Result<T>`/`Failure` hierarchy, `Uuid.v7()`, `Clock`, `Logger`
- [x] `vf_protocol`: freezed DTOs for Folder/Document/Note, `SyncOp`, `EntityType`, `PushRequest/Response`, `ChangesResponse`, `UploadSession*`, `ApiErrorCode`, `ApiPaths`
- [x] `vf_ui`: color/typography tokens, light/dark `ThemeData`, `Breakpoints`, `AdaptiveScaffold`, `EmptyState`, `SyncStatusBadge`
- [x] App: `ProviderScope`, `go_router` with ShellRoute + placeholder pages for all routes, `usePathUrlStrategy()` on web, `window_manager` on desktop
- [x] Golden tests for `AdaptiveScaffold` at 400/700/1200 px
- **Exit**: navigable shell on phone, desktop and web with correct layouts and URLs.
- **Done 2026-09-06.** Notes: router uses `StatefulShellRoute.indexedStack` (one branch per destination, so tab stacks survive switching) with an auth `redirect` that preserves the deep link as `?from=`; the session is a placeholder Riverpod notifier until Phase 3. Generated `*.g.dart` / `*.freezed.dart` files are committed. Golden tests are generated on macOS; the comparator (`packages/vf_ui/test/flutter_test_config.dart`) enforces a 0.5 % pixel tolerance on macOS only and just reports the difference on Linux CI, because text rasterisation differs across platforms by more than any sane tolerance (CI failed with the tolerant comparator alone). The layout assertions in the same tests are what CI guarantees.

### Phase 2 — Local database & fully offline CRUD
- [x] `vf_database`: Drift tables from §3.1, DAOs (`FoldersDao`, `DocumentsDao`, `NotesDao`, `OutboxDao`, `TransfersDao`, `ConflictsDao`), FTS5 for notes, migration strategy, `openDatabase()` per platform (SQLCipher native / wasm web)
- [x] `vf_security.DbKeyProvider` (random key → secure storage) — minimal slice needed by the DB opener
- [x] `vf_domain`: entities, `VaultRepository`, `NotesRepository` interfaces, use cases (`CreateFolder`, `MoveItem`, `RenameItem`, `SoftDelete`, `SaveNote`…)
- [x] Repository impls in `vf_database` write entity + **outbox row in one transaction** (coalescing rules)
- [x] Features `vault` (tree, list/grid, breadcrumb, create/rename/move/delete, import file via `file_picker` → copies to cache dir, `cache_state=complete`) and `notes` (list + Markdown editor with autosave)
- [x] Tests: DAO tests on in-memory Drift, coalescing rules, use-case tests with fakes
- **Exit**: full CRUD works with no network; outbox fills up correctly (inspectable in a debug screen).
- **Done 2026-09-06.** Notes: `package:sqlite3` 3.x bundles SQLite through Dart hooks, so the EOL `sqlite3_flutter_libs`/`sqlcipher_flutter_libs` packages are not used; the workspace `pubspec.yaml` selects `source: sqlite3mc` (SQLite3MultipleCiphers, ChaCha20) and `applyKey` refuses to open a vault when `PRAGMA cipher` is missing. Web uses `web/sqlite3.wasm` + `web/drift_worker.js` (drift 2.34.4 release assets) unencrypted; **the web app must be served with `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`** so drift can use OPFS — verified in Chrome that without them the IndexedDB fallback loses the last seconds of writes on reload. Build web with `--no-web-resources-cdn` so the engine assets are same-origin under COEP. macOS keychain uses the legacy (non data-protection) keychain because the data-protection one needs a team-signed `keychain-access-groups` entitlement. Root is `folderId == null` everywhere (protocol DTOs made nullable). FTS5 is an external-content table kept in sync by triggers; queries are tokenised into quoted prefix terms so user input cannot inject FTS operators. Imported files are content-addressed under `<app support>/vaultflow/cache/<hash[0:2]>/<hash>/<name>`; on web the file is hashed and registered with `cache_state = none` until Phase 5 uploads it. Sync queue debug screen lives at `/settings/outbox`.

### Phase 3 — Auth, network client, vault lock
- [x] Server: migrations `0001_init.sql` (users, devices, refresh_tokens), `/auth/*` routes, Argon2id, JWT, refresh rotation + reuse detection, auth middleware, request-id/error middleware
- [x] `vf_network`: `DioFactory`, `AuthInterceptor` (single-flight refresh), `ConnectivityMonitor` stream, `ApiClient` typed over `vf_protocol`
- [x] `vf_security`: `SecureStore`, `BiometricGate`, `PinVault`, `AppLockController` + lifecycle hooks, privacy cover
- [x] Features `auth` (login/register, session restore), `lock` (lock overlay, biometric prompt, PIN setup/fallback), `settings` (lock timeout, biometrics toggle, logout = wipe)
- [x] Tests: server auth integration tests (Postgres in Docker), interceptor refresh single-flight test, `AppLockController` tests with fake clock
- **Exit**: log in on device, background the app, return → biometric lock; token refresh transparent.
- **Done 2026-09-07.** Notes: the server runs on an `AuthStore` interface — `PostgresAuthStore` in production, `InMemoryAuthStore` for tests and for `dart_frog dev` without `DATABASE_URL` (Docker was not available on the dev machine, so the Postgres store test skips unless `TEST_DATABASE_URL` is set; CI runs a `postgres:16-alpine` service, applies `bin/migrate.dart`, and exports `TEST_DATABASE_URL` so the integration test runs there). Passwords use Argon2id (PHC strings, OWASP 19 MiB/2 iterations, tunable via `ARGON2_*`), access tokens are HS256 JWTs (15 min), refresh tokens are opaque and stored hashed; every refresh rotates within a `family_id` and replaying a rotated token revokes the whole family. `GET /auth/me` was added for session restore. The Dio `AuthInterceptor` is a `QueuedInterceptorsWrapper`; refresh and replay calls go through a bare Dio because routing them through the queue deadlocks on itself. Lock policy: the vault only locks when a PIN is set; biometrics are a shortcut with PIN fallback; a cold start with a PIN starts locked; `inactive` draws a privacy cover. PIN guesses are rate-limited by `PinVault` (5 attempts, 30 s doubling to 15 min). Biometrics need `NSFaceIDUsageDescription` (iOS/macOS), `FlutterFragmentActivity` + `USE_BIOMETRIC` (Android). Sign out revokes the token family and wipes every table, cached file, token, PIN and lock setting. CORS is enabled on the server (`CORS_ALLOWED_ORIGINS`, default `*`).

### Phase 4 — Sync engine & conflict resolution
- [x] Server: migrations for folders/documents/notes/changes/applied_ops; `SyncService.applyOps` (version check, change log, idempotency); `/sync/push`, `/sync/changes`
- [x] `vf_sync`: `OutboxProcessor` (FIFO, batching, backoff, `blocked` handling), `ChangePuller` (cursor paging, skip-if-pending), `ConflictDetector` → `conflicts` table, `SyncScheduler` (triggers in §4.1), `workmanager` periodic task on mobile
- [x] Feature `conflicts`: badge, resolver sheet (keep mine / theirs / both), sync status indicator in app bar, "Sync now"
- [x] Tests: server conflict/idempotency tests; client sync tests against an in-process fake server; **two-device simulation test** (two DBs, one server, edit same note offline on both, reconnect → exactly one conflict)
- **Exit**: edits made offline on two devices converge; conflicts are visible and resolvable.
- **Done 2026-09-08.** Notes: server `SyncService` sits on a `SyncStore` interface (Postgres + in-memory, like auth); entity ids are TEXT UUID v7; a `create` for an existing id is a conflict; `changes` fetches limit+1 to compute `has_more`. **Pushes for one user are serialised** (per-user mutex in memory, `pg_advisory_xact_lock(hashtext(user_id))` per op transaction on Postgres): the live two-browser run showed two devices pushing 8 ms apart both being applied because each transaction read the old version — now covered by a concurrency test. `vf_sync` tests run the client against the **real server `SyncService`** (dev-dependency on `vaultflow_server` behind `FakeAdapter`), including the two-device simulation. Client `OutboxProcessor`: FIFO batches of 100, backoff 1 s doubling to 5 min with jitter, `failed` after 10 attempts with a Retry action; an edit that lands while its batch is in flight stays `pending` and is pushed next round (it conflicts if the versions crossed — documented outcome). `ChangePuller` skips entities with any unsynced outbox row or an open conflict. `SyncScheduler` triggers: start, connectivity regained, outbox growth debounced 2 s, app resume, every 15 min; mobile background rounds use workmanager (`dev.vaultflow.sync`, iOS `BGTaskSchedulerPermittedIdentifiers` + AppDelegate registration, Android needs nothing). The `SyncCoordinator` provider creates/tears down the engine with the session; widget tests disable the scheduler via `syncEnabledProvider`. Conflicts are resolved from the badge sheet, `/settings/conflicts`, the item menu, or a banner in the note editor.

### Phase 5 — Resumable large-file transfers
- [x] Server: `StorageAdapter` (`S3Storage` via MinIO, `LocalFsStorage`), `upload_sessions` migration, `/uploads*` routes, sha256 verification, blob dedupe, ranged `/documents/{id}/content` (206, ETag), expired-session GC
- [x] `vf_transfer`: `ChunkPlanner`, `UploadWorker` (3 parallel chunks, reconcile via `GET /uploads/{id}`), `DownloadWorker` (Range resume, `.part` files), `Hasher` in isolate, `TransferEngine` pool + pause/resume/cancel + persistence
- [x] Wire `depends_on_transfer` between outbox document creates and upload sessions; auto-download on open; "Make available offline" toggle
- [x] Feature `transfers`: queue list, per-item progress/speed/ETA, pause/resume/cancel/retry, bytes-saved-by-dedupe
- [x] Tests: fault-injecting test server (drops connection at random byte), kill-app-mid-upload integration test resumes from persisted chunk state, download resume test, hash-mismatch test
- **Exit**: a 1 GB file survives airplane-mode toggles and app kills without restarting.
- **Done 2026-09-09.** Notes: `StorageAdapter` stores upload parts separately and assembles on `complete`; `LocalFsStorage` is the tested default (`STORAGE_BACKEND=local`, `STORAGE_ROOT`), `S3Storage` (MinIO) stores parts as objects and concatenates with a streaming `putObject` because the `minio` Dart client does not expose part uploads; verified against MinIO with the `StorageAdapter` contract test (`test/storage`, runs on both backends, S3 gated by `TEST_S3_ENDPOINT`, a MinIO service in CI) and the live smoke on `STORAGE_BACKEND=s3`. Blobs are content-addressed per user (`u/<user>/<sha[0:2]>/<sha>`) with `(user_id, sha256)` dedupe; `POST /uploads` returns `dedup: true` instantly for known content. Chunks are verified per request (`X-Chunk-Sha256`, exact length) and idempotent; `complete` re-hashes the assembled object and refuses mismatches. A document whose create is still queued client-side is not on the server yet, so `complete` returns `version: 0` and the **client** patches `storage_key` into the blocked outbox create before releasing it; the sync service rejects document snapshots whose `storage_key` is not a blob the user owns. Client engine: pool of 2 sessions, 3 parallel chunks, retry backoff kept in memory (row stays `queued`), `failed` after 8 attempts, crash recovery via `running → queued` at start; downloads resume from the `.part` length with `Range`, verify sha256 in an isolate, and land in the content-addressed cache. `vf_transfer` tests run against the real server `UploadService`/`ContentService` behind the fake adapter, with fault injection (dropped chunk PUTs, downloads cut at a byte offset, a kill between chunks, corrupted objects). Web uploads/downloads are deferred to Phase 6 (no filesystem; picked bytes are hashed only). `packages/vf_transfer/test/live` is an opt-in end-to-end run over real HTTP (`VAULTFLOW_LIVE_API`): 12 MiB chunked upload, sync, ranged download on a second device, dedupe, `.part` resume. dart_frog gotcha: a route parameter cannot be named `index` (`[index].dart` collides with the directory route), hence `chunks/[n].dart`.

### Phase 6 — Adaptive UX polish & platform integration
- [x] Drag & drop: `desktop_drop` OS-file drops → import into target folder; in-app `Draggable`/`DragTarget` moves with drop highlighting
- [x] Desktop: context menus, keyboard `Shortcuts`/`Actions`, resizable sidebar, multi-select
- [x] Search (FTS5 notes + name search) with `/search?q=` route
- [x] Web: deep-link restore, PWA manifest, downloads via short-lived signed URL (web can't write ranged `.part` files)
- [x] Mobile: share-sheet import, pull-to-refresh sync, iOS `BGTaskScheduler`/Android foreground service for long transfers (optional, behind a flag)
- [x] Optional SSE `/sync/events` realtime nudge
- [x] Accessibility pass (semantics, focus order, contrast), i18n scaffolding
- **Exit**: UX parity checklist in `docs/platforms.md` fully ticked per platform.
- **Done 2026-09-09.** Notes: in-app moves use `Draggable` with the mouse and `LongPressDraggable` on touch, where long-press-and-release toggles selection and long-press-and-move drags (one gesture, no arena fight); drop targets are folder rows, the sidebar tree, and breadcrumb entries. OS drops use `desktop_drop` around the vault page. Multi-select is a `Map<id, VaultRef>` provider cleared on navigation; batch move/delete run per item and report the first failure. App-wide shortcuts (⌘N/⌘⇧N/⌘I/⌘F, Ctrl elsewhere) live above the router in `GlobalShortcuts` so they work whichever branch holds focus; selection shortcuts (⌘A, Esc, Del, F2) live in the vault page. Search is `/search?q=` in the vault branch: `VaultRepository.searchByName` (escaped `LIKE`, prefix matches first) plus notes FTS, re-run live on any table change. Web: signed download links (`POST /documents/{id}/download-url` → 5-minute JWT bound to one document, accepted by `authOrDownloadToken` on the content route with `Content-Disposition: attachment`), uploads from memory (`TransferEngine.enqueueUpload(bytes:)`, parked as failed after a reload), PWA manifest, path URLs restored through `?from=`. Realtime: `GET /sync/events` is SSE polled server-side every 2 s per connection (`latestChange`), ignores the caller's own device, pings every 15 s and closes after `EVENTS_MAX_AGE_MINUTES` (the route sets shelf's `buffer_output` context to false, otherwise `dart:io` holds the small writes back — found by the curl live check, not by the in-process route test); `SyncScheduler.eventSource` reconnects with exponential backoff, disabled on web (dio's browser adapter buffers). Android share sheet: `MainActivity` copies `ACTION_SEND[_MULTIPLE]` URIs into the cache and hands paths to Dart over `dev.vaultflow/share`; iOS needs a share-extension target (deferred to Phase 7, see `docs/platforms.md`). Persisted UI prefs: view mode and sidebar width in `app_settings`. i18n scaffold: `l10n.yaml` + `lib/l10n/app_en.arb` with the shell strings migrated. Accessibility: semantic labels on tree toggles and the resize handle; every icon button has a tooltip.

### Phase 7 — Production hardening
- [ ] Observability: structured logs, optional Sentry (client + server), sync/transfer metrics
- [ ] Server: rate limiting, request size limits, CORS for web origin, graceful shutdown, Dockerfile + `docker compose up` prod profile, backup notes for Postgres/MinIO
- [ ] Client: crash-safe DB migrations test (upgrade from every prior schema), storage quota handling, low-disk behavior
- [ ] E2E: `integration_test` suite (login → create → sync → conflict → transfer) run in CI on macOS + Android emulator
- [ ] Release: app icons/splash, flavors (dev/staging/prod via `--dart-define`), signing docs, CHANGELOG
- [ ] Security review checklist (token lifetimes, lock bypass attempts, path traversal in storage keys, chunk-size abuse)

---

## 8. Verification Strategy (applies every phase)

Manual walkthroughs per phase live in [docs/MANUAL_TESTING.md](MANUAL_TESTING.md) and are updated at the end of every phase.

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
