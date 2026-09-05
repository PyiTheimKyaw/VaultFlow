import 'package:flutter_test/flutter_test.dart';
import 'package:vf_database/vf_database.dart';

void main() {
  test('package is wired into the workspace', () {
    expect(vfDatabasePackageName, 'vf_database');
  });
}
