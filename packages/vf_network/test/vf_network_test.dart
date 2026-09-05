import 'package:flutter_test/flutter_test.dart';
import 'package:vf_network/vf_network.dart';

void main() {
  test('package is wired into the workspace', () {
    expect(vfNetworkPackageName, 'vf_network');
  });
}
