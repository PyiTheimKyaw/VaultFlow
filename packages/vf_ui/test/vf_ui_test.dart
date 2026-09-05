import 'package:flutter_test/flutter_test.dart';
import 'package:vf_ui/vf_ui.dart';

void main() {
  test('package is wired into the workspace', () {
    expect(vfUiPackageName, 'vf_ui');
  });
}
