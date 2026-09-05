# ADR 0001 — Technical stack and architecture

- **Status:** Accepted
- **Date:** 2026-09-05

## Context

VaultFlow is a personal cloud vault and workspace that must work fully offline, sync two-way with
conflict handling, transfer multi-GB files resumably, lock behind biometrics, and run on Android,
iOS, macOS, Windows and Web from one codebase. The full blueprint is in [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md).

## Decisions

| Area | Decision | Alternatives rejected |
|---|---|---|
| Client framework | Flutter 3.47 / Dart 3.13 | — |
| Monorepo | Dart **pub workspaces** (`apps/`, `packages/`) | melos (extra tool; workspaces are built in) |
| State / DI | **Riverpod 3** + codegen | Bloc (more boilerplate for this team size) |
| Local DB | **Drift** (SQLite) — SQLCipher on native, wasm on web | Isar / ObjectBox (weak or no web support) |
| Network | **Dio** + `connectivity_plus` | `http` (no interceptors, cancel tokens, progress) |
| Routing | **go_router** with path URL strategy | Navigator 2 by hand |
| Backend | Self-hosted **Dart Frog** + Postgres 16 + S3-compatible storage (MinIO in dev) | Supabase (fixed TUS protocol, logic in SQL), Node/Go (second toolchain, no shared code) |
| Encryption scope | **Device-secured**: Keychain/Keystore secrets, encrypted local DB, TLS | Full E2EE (deferred; complicates chunk resumption, search and recovery) |
| Conflicts | **Per-entity version + conflicted copy** with resolver UI | CRDT text merge (large subsystem, deferred) |
| Shared contract | `vf_protocol` pure-Dart package used by both app and server | OpenAPI codegen |

## Consequences

- The server depends only on `vf_core` and `vf_protocol`, so those two packages must stay free of Flutter imports.
- All per-package analysis inherits `analysis_options.yaml` at the root (`very_good_analysis`).
- Generated code (`*.g.dart`, `*.freezed.dart`, `*.drift.dart`) is committed so CI and Docker builds do not need a codegen step.
- Web is a first-class UI target but a degraded security/background target; limitations are tracked in `docs/platforms.md` (Phase 6).
