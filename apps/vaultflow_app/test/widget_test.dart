import 'package:flutter_test/flutter_test.dart';
import 'package:vaultflow_app/main.dart';

void main() {
  testWidgets('renders the VaultFlow shell', (tester) async {
    await tester.pumpWidget(const VaultFlowApp());
    expect(find.text('VaultFlow'), findsOneWidget);
  });
}
