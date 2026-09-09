import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/app/router.dart';
import 'package:vaultflow_app/app/routes.dart';
import 'package:vaultflow_app/app/shell/app_shell.dart';
import 'package:vaultflow_app/features/auth/application/session_controller.dart';
import 'package:vaultflow_app/features/lock/presentation/lock_overlay.dart';
import 'package:vaultflow_app/features/vault/presentation/vault_page.dart';
import 'package:vaultflow_app/l10n/generated/app_localizations.dart';
import 'package:vf_ui/vf_ui.dart';

/// Root widget: theme + router, with the vault-lock overlay layered above
/// the router via [MaterialApp.builder] so it covers every route and the
/// URL survives locking on web.
class VaultFlowApp extends ConsumerWidget {
  const VaultFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: VfTheme.light(),
      darkTheme: VfTheme.dark(),
      routerConfig: router,
      builder: (context, child) => GlobalShortcuts(
        child: LockLifecycle(
          child: Stack(
            fit: StackFit.expand,
            children: [child ?? const SizedBox.shrink(), const LockOverlay()],
          ),
        ),
      ),
    );
  }
}

/// App-wide keyboard shortcuts (⌘N note, ⌘⇧N folder, ⌘I import, ⌘F
/// search). They sit above the router so they fire wherever keyboard focus
/// happens to be, and act on the folder currently shown in the vault (the
/// root elsewhere). Ignored while signed out or locked.
class GlobalShortcuts extends ConsumerWidget {
  const GlobalShortcuts({required this.child, super.key});

  final Widget child;

  VaultCommands? _commands(WidgetRef ref) {
    if (!ref.read(sessionControllerProvider).isSignedIn) return null;
    if (ref.read(appLockControllerProvider).isLocked) return null;
    final router = ref.read(routerProvider);
    final context = router.configuration.navigatorKey.currentContext;
    if (context == null) return null;
    final path = router.routerDelegate.currentConfiguration.uri.path;
    return VaultCommands(context, ref, AppShell.folderIdFromPath(path));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CallbackShortcuts(
      bindings: {
        for (final a in VaultCommands.cmd(LogicalKeyboardKey.keyN))
          a: () => unawaited(_commands(ref)?.newNote()),
        for (final a in VaultCommands.cmd(LogicalKeyboardKey.keyN, shift: true))
          a: () => unawaited(_commands(ref)?.newFolder()),
        for (final a in VaultCommands.cmd(LogicalKeyboardKey.keyI))
          a: () => unawaited(_commands(ref)?.import()),
        for (final a in VaultCommands.cmd(LogicalKeyboardKey.keyF))
          a: () => _commands(ref)?.context.go(AppRoutes.search),
      },
      child: child,
    );
  }
}
