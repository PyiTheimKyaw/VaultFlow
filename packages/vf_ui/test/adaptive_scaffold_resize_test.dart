import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vf_ui/vf_ui.dart';

void main() {
  const destinations = [
    AdaptiveDestination(icon: Icons.folder, label: 'A'),
    AdaptiveDestination(icon: Icons.note, label: 'B'),
  ];

  testWidgets('dragging the handle resizes the sidebar and commits once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final widths = <double>[];
    var commits = 0;
    var width = 280.0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => AdaptiveScaffold(
            destinations: destinations,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            sidebar: const Text('tree'),
            sidebarWidth: width,
            onSidebarResize: (w) {
              widths.add(w);
              setState(() => width = w);
            },
            onSidebarResizeEnd: () => commits++,
            body: const Text('body'),
          ),
        ),
      ),
    );
    final handle = find.byKey(const Key('sidebar-resize-handle'));
    expect(handle, findsOneWidget);
    await tester.drag(handle, const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(widths.last, 340);
    expect(commits, 1);
    // The sidebar box really is wider now.
    final sidebar = tester.getSize(
      find
          .ancestor(of: find.text('tree'), matching: find.byType(Material))
          .first,
    );
    expect(sidebar.width, 340);
  });

  testWidgets('no handle without a resize callback', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveScaffold(
          destinations: destinations,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          sidebar: const Text('tree'),
          body: const Text('body'),
        ),
      ),
    );
    expect(find.byKey(const Key('sidebar-resize-handle')), findsNothing);
  });
}
