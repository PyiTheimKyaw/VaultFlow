# Platform capability matrix

What each platform can do after Phase 6. ✅ works, ◐ degraded or partial,
❌ not available, — not applicable. "Deferred" items are tracked in
`ARCHITECTURE.md` under the phase that will deliver them.

| Capability | Android | iOS | macOS | Windows | Linux | Web |
|---|---|---|---|---|---|---|
| Offline CRUD (folders, files, notes) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (OPFS via COOP/COEP) |
| Encrypted local DB (SQLCipher) | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ origin isolation only |
| Two-way sync, conflicts | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Realtime nudge (`/sync/events`) | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ periodic + resume triggers |
| Background sync | ✅ workmanager | ✅ BGTaskScheduler via workmanager | ◐ in-process timer | ◐ in-process timer | ◐ in-process timer | ❌ foreground only |
| Resumable chunked upload | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ from memory, no resume after reload |
| Ranged download to cache | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ browser download via signed link |
| Open file with the OS | ✅ | ✅ | ✅ | ✅ | ✅ | — |
| Keep available offline | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Biometric unlock | ✅ | ✅ | ✅ Touch ID | ❌ PIN only | ❌ PIN only | ❌ PIN only |
| PIN lock, privacy cover | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| OS file drop into a folder | ◐ (desktop_drop) | ❌ | ✅ | ✅ | ✅ | ✅ |
| In-app drag to move | ✅ long press | ✅ long press | ✅ mouse | ✅ mouse | ✅ mouse | ✅ mouse |
| Multi-select (long press / ⌘-click) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Right-click context menu | — | — | ✅ | ✅ | ✅ | ✅ |
| Keyboard shortcuts (⌘N ⌘⇧N ⌘I ⌘F ⌘A Esc Del F2) | ◐ with keyboard | ◐ with keyboard | ✅ | ✅ Ctrl | ✅ Ctrl | ✅ |
| Resizable sidebar | — | — | ✅ | ✅ | ✅ | ✅ |
| Search (names + note text) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ `/search?q=` |
| Pull-to-refresh sync | ✅ | ✅ | — | — | — | — |
| Share-sheet import | ✅ | ❌ needs a share extension target (deferred) | — | — | — | — |
| Deep-link restore after login | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ `?from=` |
| PWA install | — | — | — | — | — | ✅ manifest |
| Localization scaffold (ARB) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Notes:

* Web durability relies on OPFS, which needs the `Cross-Origin-Opener-Policy`
  and `Cross-Origin-Embedder-Policy` headers (`scripts/serve_web.sh`).
* Web uploads keep the picked bytes in memory; reloading mid-upload parks the
  transfer as failed with a "import it again" message.
* Foreground services for long mobile transfers and the iOS share extension
  are deferred to Phase 7.
