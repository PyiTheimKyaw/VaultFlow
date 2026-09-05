import 'package:flutter/material.dart';
import 'package:vf_core/vf_core.dart';

void main() {
  runApp(const VaultFlowApp());
}

/// Temporary application shell. Replaced by the router-driven shell in Phase 1.
class VaultFlowApp extends StatelessWidget {
  const VaultFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VaultFlow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3556D8)),
      ),
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48),
              SizedBox(height: 12),
              Text('VaultFlow', style: TextStyle(fontSize: 24)),
              SizedBox(height: 4),
              Text('workspace wired: $vfCorePackageName'),
            ],
          ),
        ),
      ),
    );
  }
}
