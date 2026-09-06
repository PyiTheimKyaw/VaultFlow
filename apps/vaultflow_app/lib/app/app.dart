import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultflow_app/app/router.dart';
import 'package:vf_ui/vf_ui.dart';

/// Root widget: theme + router. The vault-lock overlay (Phase 3) is layered
/// above the router via [MaterialApp.builder] so it covers every route.
class VaultFlowApp extends ConsumerWidget {
  const VaultFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'VaultFlow',
      debugShowCheckedModeBanner: false,
      theme: VfTheme.light(),
      darkTheme: VfTheme.dark(),
      routerConfig: router,
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          child ?? const SizedBox.shrink(),
          // Lock overlay slot: added in Phase 3.
        ],
      ),
    );
  }
}
