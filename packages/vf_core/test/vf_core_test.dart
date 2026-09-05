import 'package:test/test.dart';
import 'package:vf_core/vf_core.dart';

void main() {
  test('package is wired into the workspace', () {
    expect(vfCorePackageName, 'vf_core');
  });
}
