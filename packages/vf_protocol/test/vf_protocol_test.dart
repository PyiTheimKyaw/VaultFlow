import 'package:test/test.dart';
import 'package:vf_protocol/vf_protocol.dart';

void main() {
  test('package is wired into the workspace', () {
    expect(vfProtocolPackageName, 'vf_protocol');
  });
}
