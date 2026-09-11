import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vaultflow_app/app/routes.dart';
import 'package:vaultflow_app/app/shell/app_shell.dart';
import 'package:vaultflow_app/features/auth/application/session_controller.dart';
import 'package:vaultflow_app/features/auth/presentation/login_page.dart';
import 'package:vaultflow_app/features/conflicts/presentation/conflicts_page.dart';
import 'package:vaultflow_app/features/lock/presentation/lock_settings_page.dart';
import 'package:vaultflow_app/features/notes/presentation/note_editor_page.dart';
import 'package:vaultflow_app/features/notes/presentation/notes_page.dart';
import 'package:vaultflow_app/features/search/presentation/search_page.dart';
import 'package:vaultflow_app/features/settings/presentation/diagnostics_page.dart';
import 'package:vaultflow_app/features/settings/presentation/outbox_debug_page.dart';
import 'package:vaultflow_app/features/settings/presentation/settings_page.dart';
import 'package:vaultflow_app/features/settings/presentation/storage_page.dart';
import 'package:vaultflow_app/features/transfers/presentation/transfers_page.dart';
import 'package:vaultflow_app/features/vault/presentation/vault_page.dart';

part 'router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Notifies the router when the session changes so redirects re-run without
/// rebuilding the whole router (which would drop navigation state).
class _SessionRefresh extends ChangeNotifier {
  _SessionRefresh(Ref ref) {
    ref.listen(sessionControllerProvider, (_, _) => notifyListeners());
  }
}

@riverpod
GoRouter router(Ref ref) {
  final refresh = _SessionRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.vault,
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final signedIn = ref.read(sessionControllerProvider).isSignedIn;
      final atLogin = state.matchedLocation == AppRoutes.login;
      if (!signedIn && !atLogin) {
        final from = state.uri.toString();
        return from == AppRoutes.vault
            ? AppRoutes.login
            : Uri(
                path: AppRoutes.login,
                queryParameters: {'from': from},
              ).toString();
      }
      if (signedIn && atLogin) {
        return state.uri.queryParameters['from'] ?? AppRoutes.vault;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.vault),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.vault,
                name: AppRoutes.vaultName,
                builder: (context, state) => const VaultPage(),
                routes: [
                  GoRoute(
                    path: ':${AppRoutes.folderParam}',
                    name: AppRoutes.folderName,
                    builder: (context, state) => VaultPage(
                      folderId: state.pathParameters[AppRoutes.folderParam],
                    ),
                  ),
                ],
              ),
              // Lives in the vault branch so opening a hit keeps the
              // vault stack and the Vault destination stays selected.
              GoRoute(
                path: AppRoutes.search,
                name: AppRoutes.searchName,
                builder: (context, state) => SearchPage(
                  query: state.uri.queryParameters[AppRoutes.searchParam] ?? '',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.notes,
                name: AppRoutes.notesName,
                builder: (context, state) => const NotesPage(),
                routes: [
                  GoRoute(
                    path: ':${AppRoutes.noteParam}',
                    name: AppRoutes.noteName,
                    builder: (context, state) => NoteEditorPage(
                      noteId: state.pathParameters[AppRoutes.noteParam]!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.transfers,
                name: AppRoutes.transfersName,
                builder: (context, state) => const TransfersPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                name: AppRoutes.settingsName,
                builder: (context, state) => const SettingsPage(),
                routes: [
                  GoRoute(
                    path: 'outbox',
                    name: AppRoutes.settingsOutboxName,
                    builder: (context, state) => const OutboxDebugPage(),
                  ),
                  GoRoute(
                    path: 'lock',
                    name: AppRoutes.settingsLockName,
                    builder: (context, state) => const LockSettingsPage(),
                  ),
                  GoRoute(
                    path: 'conflicts',
                    name: AppRoutes.settingsConflictsName,
                    builder: (context, state) => const ConflictsPage(),
                  ),
                  GoRoute(
                    path: 'diagnostics',
                    name: AppRoutes.settingsDiagnosticsName,
                    builder: (context, state) => const DiagnosticsPage(),
                  ),
                  GoRoute(
                    path: 'storage',
                    name: AppRoutes.settingsStorageName,
                    builder: (context, state) => const StoragePage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
