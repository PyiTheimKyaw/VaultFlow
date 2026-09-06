import 'package:flutter/material.dart';
import 'package:vf_ui/vf_ui.dart';

class TransfersPage extends StatelessWidget {
  const TransfersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      key: Key('transfers'),
      icon: Icons.swap_vert_outlined,
      title: 'No transfers',
      message: 'Resumable uploads and downloads show their progress here.',
    );
  }
}
