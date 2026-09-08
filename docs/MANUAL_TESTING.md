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

## 7. Phase 5 — resumable transfers (pending)

To be written when Phase 5 lands.

## 8. Phase 6 — adaptive UX polish (pending)

To be written when Phase 6 lands.

## 9. Phase 7 — production hardening (pending)

To be written when Phase 7 lands.
