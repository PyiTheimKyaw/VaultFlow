import 'package:flutter_test/flutter_test.dart';
import 'package:vf_sync/vf_sync.dart';

void main() {
  test('package is wired into the workspace', () {
    expect(vfSyncPackageName, 'vf_sync');
  });
}
