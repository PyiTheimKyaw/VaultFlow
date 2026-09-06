import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vf_ui/vf_ui.dart';

void main() {
  test('Breakpoints.classify follows the 600/840 thresholds', () {
    expect(Breakpoints.classify(0), WindowSizeClass.compact);
    expect(Breakpoints.classify(599.9), WindowSizeClass.compact);
    expect(Breakpoints.classify(600), WindowSizeClass.medium);
    expect(Breakpoints.classify(839.9), WindowSizeClass.medium);
    expect(Breakpoints.classify(840), WindowSizeClass.expanded);
    expect(Breakpoints.classify(2000), WindowSizeClass.expanded);
  });

  test('WindowSizeClass ordering', () {
    expect(WindowSizeClass.expanded >= WindowSizeClass.medium, isTrue);
    expect(WindowSizeClass.compact >= WindowSizeClass.medium, isFalse);
    expect(WindowSizeClass.medium.isMedium, isTrue);
  });

  testWidgets('context.windowSizeClass reads MediaQuery', (tester) async {
    late WindowSizeClass seen;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(700, 500)),
        child: Builder(
          builder: (context) {
            seen = context.windowSizeClass;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen, WindowSizeClass.medium);
  });

  testWidgets('themes expose semantic colours', (tester) async {
    expect(VfTheme.light().extension<VfSemanticColors>(), isNotNull);
    expect(VfTheme.dark().brightness, Brightness.dark);
    late VfSemanticColors colors;
    await tester.pumpWidget(
      Theme(
        data: VfTheme.dark(),
        child: Builder(
          builder: (context) {
            colors = context.semanticColors;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(colors.success, const VfSemanticColors.dark().success);
  });

  testWidgets('SyncStatusBadge renders label and semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: VfTheme.light(),
        home: const Scaffold(
          body: Column(
            children: [
              SyncStatusBadge(status: SyncBadgeStatus.conflicted),
              SyncStatusBadge(status: SyncBadgeStatus.syncing, compact: true),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Conflict'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Sync status: Conflict'), findsOneWidget);
    semantics.dispose();
  });
}
