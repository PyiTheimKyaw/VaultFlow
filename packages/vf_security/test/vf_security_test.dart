import 'package:flutter_test/flutter_test.dart';
import 'package:vf_security/vf_security.dart';

void main() {
  test('package is wired into the workspace', () {
    expect(vfSecurityPackageName, 'vf_security');
  });
}
