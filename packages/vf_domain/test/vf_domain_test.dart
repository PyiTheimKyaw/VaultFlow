import 'package:test/test.dart';
import 'package:vf_domain/vf_domain.dart';

void main() {
  test('package is wired into the workspace', () {
    expect(vfDomainPackageName, 'vf_domain');
  });
}
