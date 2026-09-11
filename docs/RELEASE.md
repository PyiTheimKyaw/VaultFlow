# Release guide

## Flavors

Build-time configuration comes from `--dart-define-from-file`:

| File | `VAULTFLOW_ENV` | API |
|---|---|---|
| `env/dev.json` | dev | http://localhost:8080 |
| `env/staging.json` | staging | https://staging.api.vaultflow.example |
| `env/prod.json` | prod | https://api.vaultflow.example |

Edit the URLs and add `SENTRY_DSN` per environment. Set
`VAULTFLOW_VERSION` to the marketing version at build time (it is shown in
Settings › Diagnostics and used as the Sentry release):

```bash
flutter build macos --release --dart-define-from-file=env/prod.json --dart-define=VAULTFLOW_VERSION=0.7.0
flutter build web --release --no-web-resources-cdn --dart-define-from-file=env/prod.json
flutter build appbundle --release --dart-define-from-file=env/prod.json
flutter build ipa --release --dart-define-from-file=env/prod.json
```

## Icons and splash

Source art lives in `assets/icon/`. Regenerate platform assets after
changing it:

```bash
cd apps/vaultflow_app
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Signing

**Android**: create a keystore once and keep it out of git:

```bash
keytool -genkey -v -keystore ~/keys/vaultflow-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties` (git-ignored):

```
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=/Users/you/keys/vaultflow-upload.jks
```

and reference it from `android/app/build.gradle.kts` `signingConfigs.release`
(the standard Flutter recipe). Bump `versionCode`/`versionName` in
`pubspec.yaml` (`version: 0.7.0+7`).

**iOS / macOS**: open `ios/Runner.xcworkspace` (or `macos/`) in Xcode once,
set the team and bundle id (`dev.vaultflow.app`), enable automatic signing.
macOS needs the Keychain and Local Network entitlements already present in
`macos/Runner/*.entitlements`; distribution outside the App Store must be
notarised (`xcrun notarytool`).

**Windows**: `flutter build windows`, then package with MSIX
(`dart run msix:create`) using a code-signing certificate.

**Web**: serve `build/web` with `Cross-Origin-Opener-Policy: same-origin` and
`Cross-Origin-Embedder-Policy: require-corp` (OPFS needs them), plus
`Cache-Control: no-cache` on `index.html`/`flutter_bootstrap.js`.

## Checklist

1. `scripts/check.sh` green; CI green on `develop`.
2. Bump versions: `pubspec.yaml` (app), `apps/vaultflow_server/lib/version.dart`, `CHANGELOG.md`.
3. Record the DB schema if tables changed: `scripts/schema.sh`, commit `drift_schemas/` and `test/generated/`.
4. Tag `vX.Y.Z`, build the server image, `docker compose --profile api up -d --build` (see `docs/OPERATIONS.md`).
5. Run the end-to-end suite against staging: `VAULTFLOW_API_BASE_URL=https://staging… flutter test integration_test -d macos`.
6. Ship clients; the server is backward compatible within a protocol version (`X-VaultFlow-Protocol`).
