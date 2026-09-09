# Manual testing guide

Step-by-step flows for trying VaultFlow by hand. This file is updated at the
end of every phase; each phase section lists what became testable and how.

## 1. Start the API server

The app needs the server for sign-in and sync. Vault, notes and the lock work
offline once you are signed in.

```bash
scripts/dev_server.sh
```

- Runs `dart_frog dev` on `http://localhost:8080` with an **in-memory store**:
  no Postgres needed, but accounts and data vanish when the server stops or
  hot-reloads after a code change.
- To keep data across restarts (and for the offline test below), point it at
  Postgres; migrations are applied automatically:

  ```bash
  DATABASE_URL="postgres://postgres:postgres@localhost:5433/vaultflow_test" scripts/dev_server.sh
  ```

- Check it is up: `curl localhost:8080/health`.

Optional settings are read from `.env` (copy `.env.example`); only
`JWT_SECRET` matters for local runs and the script provides a default.

## 2. Run the app

| Target | Command / notes |
|---|---|
| macOS | `cd apps/vaultflow_app && flutter run -d macos` |
| Web | `scripts/serve_web.sh` then open `http://127.0.0.1:8765`. Do **not** use `flutter run -d chrome` for persistence checks: the plain dev server lacks the COOP/COEP headers, so the browser falls back to IndexedDB, which can lose the last seconds of writes on reload. |
| iOS simulator | `flutter run -d <simulator id>`; `localhost` reaches the server. |
| Android emulator | `flutter run -d <emulator id> --dart-define=VAULTFLOW_API_BASE_URL=http://10.0.2.2:8080` |
| Physical device | Same `--dart-define` with your computer's LAN IP, e.g. `http://192.168.1.10:8080`; for web `API=http://192.168.1.10:8080 scripts/serve_web.sh`. |

Troubleshooting:

- Android, first build: Flutter may install "Android SDK Platform 37" (needed
  by `flutter_secure_storage`) during the Gradle run and then fail with
  `Failed to find target with hash string 'android-37'`. Just run the build
  again; the app pins `compileSdk` to at least 37.
- A physical phone cannot reach `localhost` on your computer: pass
  `--dart-define=VAULTFLOW_API_BASE_URL=http://<your-computer-LAN-IP>:8080`
  and make sure both are on the same network (`ipconfig getifaddr en0` on
  macOS prints the IP).
- The Gradle warning about `workmanager_android` applying the Kotlin Gradle
  Plugin is informational until a newer plugin release.

Automated gate for reference: `scripts/check.sh` runs format, analyze and every
test suite.

## 3. Phase 1 — shell and navigation

1. Resize the window (or use different devices): under 600 px a bottom bar,
   600–840 px a navigation rail, wider a persistent sidebar.
2. URLs: on web, `/vault`, `/notes`, `/transfers`, `/settings` are addressable
   and survive reload; a deep link visited while signed out returns you there
   after sign-in.

## 4. Phase 2 — offline vault and notes

1. Vault: "New folder" creates a folder; open it from the list or the sidebar
   tree; the breadcrumb navigates back. Rename, "Move to…" and Delete live in
   the item's ⋯ menu (long-press on touch). Toggle list/grid with the icon.
2. "Import" copies a file into the encrypted local cache; the row shows its
   size and "offline".
3. Notes: "New note" opens the editor; type and see "Saved" after about a
   second; the eye icon toggles Markdown preview.
4. Everything above works with the server stopped. The top-right badge shows
   "Pending" while edits are queued; Settings → Sync queue lists them.
5. Persistence: quit and relaunch (or reload the web page); folders, notes and
   imports are still there.

## 5. Phase 3 — accounts and vault lock

1. Sign in screen: "New here?" switches to registration; use any email and a
   password of at least 8 characters. Wrong password shows the server's
   message; with the server down you get "Cannot reach the server".
2. Relaunch the app: you land in the vault without seeing the login screen
   (session restored from the keychain).
3. Settings → Vault lock: set a PIN (4–8 digits, confirmed twice). Enable
   "Unlock with biometrics" if the device has Touch ID / Face ID. Choose
   "Lock after".
4. "Lock now" shows the lock screen over the current page. Enter a wrong PIN
   (message with attempts left), then the right one. Five wrong PINs lock the
   pad for 30 s with a countdown.
5. Background the app (switch apps, minimise) and come back after the chosen
   timeout: the lock screen appears; with biometrics enabled it prompts
   immediately. Switching apps briefly shows a blank privacy cover.
6. Relaunch with a PIN set: the app starts locked on the same page.
7. Settings → Sign out: confirm; local data is wiped and the login screen
   returns. Signing in again pulls your data back from the server.

## 6. Phase 4 — two-way sync and conflicts

Use two clients on the same account, e.g. the macOS app and the web app.

1. Create a note on A. Within a few seconds B shows it; to force it, tap B's
   badge and "Sync now".
2. Edit the note on B; A picks up the change the same way.
3. Conflict: stop the server (with Postgres, so the account survives) or
   disconnect one device's network. Edit the **same** note on A and B; both
   badges show "Offline". Restart the server / reconnect, then "Sync now" on
   A first, then on B.
4. B's badge turns "Conflict"; the note shows a banner with "Resolve"; the
   item's ⋯ menu gains "Resolve conflict…"; Settings → Conflicts lists it.
5. Open the conflict. "Keep mine" pushes your version, "Keep theirs" takes the
   server's, "Keep both" keeps the server's and saves yours as
   "<name> (Conflicted copy, <device>, <date>)". After syncing both clients
   they show identical lists.
6. Sync queue page: "Sync now" and, when ops have failed ten times, "Retry
   failed".
7. Background sync on phones (workmanager) runs roughly every 15 minutes when
   the OS allows it; it is not observable on demand.

## 7. Phase 5 — resumable transfers

Uploads and downloads need the server; files are stored under
`apps/vaultflow_server/.storage` by default (set `STORAGE_ROOT` or
`STORAGE_BACKEND=s3` with the `S3_*` variables for MinIO).

1. Import a large file (tens of MB) in the vault. The Transfers tab shows it
   uploading in chunks with speed and ETA; the vault row shows "offline" and
   the ⋯ menu's details sheet shows "Uploading…", then "Uploaded". The sync
   badge goes Pending → Synced once the create is pushed with its storage key.
2. Kill test: while a big upload is running, force-quit the app (or Ctrl+C
   `flutter run`), relaunch, sign in if needed. Transfers shows the same item
   continuing from where it stopped; the server log shows only the missing
   chunks being PUT.
3. Offline test: turn off Wi-Fi mid-upload. The item retries with backoff
   ("Retrying (attempt N)"); turn Wi-Fi back on and it finishes. After
   8 failed attempts it is parked as Failed with a Retry button.
4. Pause / Resume / Cancel from the Transfers tab. Cancelling a download
   deletes its `.part` file.
5. Dedupe: import the same file again under another name. It completes
   instantly and the Transfers header shows "N MB saved by dedupe".
6. Download: on a second device (or after "Keep available offline" off →
   on), open the document's details sheet and tap Download / switch on
   "Keep available offline". Progress shows in the sheet and in Transfers;
   when done the sheet offers Open, which launches the file with the OS.
7. Resume test: start a download, kill the app or drop the network halfway,
   come back: it continues from the `.part` offset (server log shows a
   `Range` request), verifies the hash and lands in the cache.
8. Hash mismatch: corrupt an object under `.storage/u/<user>/…` on the
   server, then download it: the transfer fails with "failed verification"
   and no cached copy is kept.
9. Web: import registers the metadata only; downloads/uploads on web arrive
   with Phase 6.

S3 backend (MinIO): `docker compose up -d minio minio-init`, then start the
server with `STORAGE_BACKEND=s3 S3_ENDPOINT=localhost S3_PORT=9000
S3_ACCESS_KEY=vaultflow S3_SECRET_KEY=vaultflow-secret S3_BUCKET=vaultflow
scripts/dev_server.sh` and repeat steps 1–7. Objects appear in the MinIO
console at http://localhost:9001 under `u/<user>/…`. The adapter contract
test runs against it with:

```bash
cd apps/vaultflow_server
TEST_S3_ENDPOINT=localhost:9000 dart test test/storage
```

Automated end-to-end check over real HTTP (upload in chunks, sync, ranged
download on a second device, dedupe, `.part` resume), with the dev server
running:

```bash
cd packages/vf_transfer
VAULTFLOW_LIVE_API=http://localhost:8080 flutter test test/live
```

## 8. Phase 6 — adaptive UX and platform integration

1. Search: tap the magnifier (or ⌘F / Ctrl+F). Type part of a folder or file
   name and a word from a note body; both appear grouped. The URL becomes
   `/search?q=…` (reload it on web). Open a hit; the Vault tab stays selected.
2. Multi-select: on desktop ⌘-click (Ctrl-click) two items, or long-press on
   touch. The toolbar becomes "N selected" with All / Move / Delete. Esc clears.
   Delete with the selection bar, then with the Delete key.
3. Drag and drop: drag a file onto a folder row, onto a folder in the sidebar
   tree, and onto a breadcrumb entry; the target highlights and "Moved 1 item"
   appears. On touch, long-press then move. Drag a selected item to move the
   whole selection.
4. OS drop (desktop, web): drag a file from Finder/Explorer onto the vault; a
   "Drop files to import here" overlay shows and the file is imported into the
   open folder and uploaded.
5. Right-click a row (desktop/web): Rename / Move / Delete menu. F2 renames a
   single selected item.
6. Shortcuts: ⌘N new note (works from any tab), ⌘⇧N new folder in the current
   folder, ⌘I import, ⌘A select all.
7. Resizable sidebar: drag the divider between the tree and the content; the
   width survives a restart. Toggle list/grid: it survives a restart too.
8. Pull-to-refresh (phone): pull down the vault or notes list; the sync badge
   spins.
9. Realtime: with two devices signed in, edit on one; within ~2 s the other
   pulls without waiting for the 15-minute timer (server log: `sync triggered
   reason=event`). Kill the server: the client reconnects with backoff.
10. Web download: on the web build, open a file's details and tap Download;
    the browser saves it (the link is valid for 5 minutes and only for that
    file). Web upload: import a file; it uploads from memory; reload mid-way
    and the transfer is parked as failed with "import it again".
11. PWA: in Chrome, "Install VaultFlow" from the address bar; it opens
    standalone at `/vault`. Deep link: open `/notes/<id>` signed out, log in,
    you land on that note.
12. Android share sheet: from Files/Photos, Share → VaultFlow. The app opens
    and "Imported <name>" appears; the file is in the vault root and uploads.

## 9. Phase 7 — production hardening (pending)

To be written when Phase 7 lands.
