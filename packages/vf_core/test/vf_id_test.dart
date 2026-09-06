import 'package:test/test.dart';
import 'package:vf_core/vf_core.dart';

void main() {
  group('VfId', () {
    test('next() yields valid, unique, time-ordered v7 ids', () {
      final a = VfId.next();
      final b = VfId.next();
      expect(VfId.isValid(a), isTrue);
      expect(a[14], '7');
      expect(a, isNot(b));
      expect(a.compareTo(b), lessThanOrEqualTo(0));
    });

    test('timestampOf extracts creation time from a v7 id', () {
      final before = DateTime.now().toUtc();
      final id = VfId.next();
      final ts = VfId.timestampOf(id)!;
      expect(ts.difference(before).inSeconds.abs(), lessThan(2));
      expect(VfId.timestampOf(VfId.random()), isNull);
      expect(VfId.timestampOf('nope'), isNull);
    });

    test('isValid rejects malformed ids', () {
      expect(VfId.isValid(''), isFalse);
      expect(VfId.isValid('ABCDEFAB-1234-7abc-8abc-123456789abc'), isFalse);
      expect(VfId.isValid(VfId.random()), isTrue);
    });
  });
}
