import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vf_ui/vf_ui.dart';

const _destinations = [
  AdaptiveDestination(
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder,
    label: 'Vault',
  ),
  AdaptiveDestination(
    icon: Icons.note_outlined,
    selectedIcon: Icons.note,
    label: 'Notes',
  ),
  AdaptiveDestination(icon: Icons.swap_vert, label: 'Transfers'),
  AdaptiveDestination(icon: Icons.settings_outlined, label: 'Settings'),
];

Widget _harness({int selectedIndex = 0, Widget? detail}) {
  return MaterialApp(
    theme: VfTheme.light(),
    debugShowCheckedModeBanner: false,
    home: AdaptiveScaffold(
      destinations: _destinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: (_) {},
      appBar: AppBar(
        title: const Text('Vault'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: SyncStatusBadge(status: SyncBadgeStatus.synced),
          ),
        ],
      ),
      sidebar: ListView(
        key: const Key('sidebar'),
        children: const [
          ListTile(
            leading: Icon(Icons.home_outlined),
            title: Text('All files'),
          ),
          ListTile(leading: Icon(Icons.history), title: Text('Recent')),
          ListTile(leading: Icon(Icons.delete_outline), title: Text('Trash')),
        ],
      ),
      body: const EmptyState(
        icon: Icons.folder_open,
        title: 'This folder is empty',
        message: 'Drop files here or create a note to get started.',
      ),
      detail: detail,
    ),
  );
}

Future<void> _setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('compact (400 px) uses a bottom navigation bar', (tester) async {
    await _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_harness());

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byKey(const Key('sidebar')), findsNothing);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    await expectLater(
      find.byType(AdaptiveScaffold),
      matchesGoldenFile('goldens/adaptive_scaffold_compact_400.png'),
    );
  });

  testWidgets('medium (700 px) uses a navigation rail', (tester) async {
    await _setSize(tester, const Size(700, 900));
    await tester.pumpWidget(_harness(selectedIndex: 1));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(const Key('sidebar')), findsNothing);
    await expectLater(
      find.byType(AdaptiveScaffold),
      matchesGoldenFile('goldens/adaptive_scaffold_medium_700.png'),
    );
  });

  testWidgets('expanded (1200 px) shows persistent sidebar and detail pane', (
    tester,
  ) async {
    await _setSize(tester, const Size(1200, 800));
    await tester.pumpWidget(
      _harness(
        detail: const Center(key: Key('detail'), child: Text('Details')),
      ),
    );

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(const Key('sidebar')), findsOneWidget);
    expect(find.byKey(const Key('detail')), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
    await expectLater(
      find.byType(AdaptiveScaffold),
      matchesGoldenFile('goldens/adaptive_scaffold_expanded_1200.png'),
    );
  });

  testWidgets('compact drawer opens the sidebar', (tester) async {
    await _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_harness());
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sidebar')), findsOneWidget);
  });
}
