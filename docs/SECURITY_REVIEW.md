# Security review checklist (Phase 7)

Each item names the control and the automated test that keeps it true.

| Area | Control | Verified by |
|---|---|---|
| Passwords | Argon2id (PHC strings), tunable memory/iterations; never logged | `test/auth/auth_service_test.dart` |
| Access tokens | HS256 JWT, 15 min TTL, `typ=access`, issuer checked, clock-based expiry | `test/auth/token_service_test.dart` |
| Refresh tokens | 30 d, opaque, hashed at rest, rotated on use; reuse of a rotated token revokes the family | `test/auth/auth_service_test.dart` (reuse detection) |
| Download links | Separate `typ=download` JWT bound to one document id, 5 min TTL; bearer still required elsewhere | `test/routes/download_link_routes_test.dart` |
| Client refresh | Single-flight refresh, no infinite loop on 401 after replay, tokens cleared on failure | `vf_network/test/auth_interceptor_test.dart` |
| Vault lock | Overlay above the router covers every route; PIN Argon2id-hashed; 5-attempt doubling backoff; biometrics gated by settings | `apps/vaultflow_app/test/lock_flow_test.dart` (cold start, timeout, lockout) |
| Lock bypass | Global shortcuts and share-sheet imports are ignored while locked; deep links open under the overlay | `lock_flow_test.dart` ("shows the lock over the current route"), `GlobalShortcuts._commands` |
| Storage keys | Every path segment sanitised; `.`/`..` neutralised; parts confined to `<root>/.uploads/<id>` | `test/http/hardening_test.dart` ("cannot escape the root") |
| Blob ownership | Sync rejects document snapshots whose `storage_key` is not the user's blob; content route checks ownership | `test/sync/sync_service_test.dart`, `test/transfer/content_service_test.dart` |
| Chunk abuse | `chunk_size ≤ MAX_CHUNK_SIZE`, PUT body bounded (413), exact length and sha256 per chunk, `total_bytes ≤ MAX_UPLOAD_BYTES`, whole-file sha256 on complete | `test/transfer/upload_service_test.dart`, `test/routes/upload_routes_test.dart`, `hardening_test.dart` |
| Request bodies | JSON bodies bounded by `MAX_JSON_BODY_BYTES` (Content-Length and streamed) | `hardening_test.dart` |
| Rate limiting | Per user/IP fixed window, stricter on `/auth/*`, preflights exempt, `Retry-After` | `hardening_test.dart` |
| Push size | `≤ vfMaxPushOps` ops per push; `changes` limit clamped to 500 | `sync_service_test.dart`, `hardening_test.dart` |
| CORS | Explicit origin allow-list, credentials never wildcarded, exposed headers limited | `test/http/middleware_test.dart` |
| Headers | `nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy`, `Cache-Control: no-store` default | `hardening_test.dart` |
| Errors | Envelope never leaks stack traces; unhandled errors logged and (optionally) sent to Sentry without request bodies | `errorHandler` |
| Local data | SQLCipher key in Keychain/Keystore; sign-out wipes DB, cache, tokens, PIN | `vf_database/test/encryption_test.dart`, `auth_flow_test.dart` (sign-out wipe) |
| Web | OPFS behind COOP/COEP; no SQLCipher (documented); tokens short-lived | `docs/platforms.md` |
| Metrics | `/metrics` disabled unless `METRICS_TOKEN` set; bearer-gated; no per-user labels | `hardening_test.dart` |

Known gaps (tracked, not blocking):

* Rate limiting is per process; multi-replica deployments need the proxy to
  enforce a global budget.
* No certificate pinning; `DioFactory` exposes a hook but production should
  decide per platform.
* Web session storage is only as strong as the browser origin.
