import 'package:flutter_test/flutter_test.dart';
import 'package:vf_transfer/vf_transfer.dart';

void main() {
  test('splits into fixed chunks with a short tail', () {
    final plans = planChunks(100, 30);
    expect(plans.map((c) => (c.index, c.offset, c.length)), [
      (0, 0, 30),
      (1, 30, 30),
      (2, 60, 30),
      (3, 90, 10),
    ]);
    expect(plans.last.end, 100);
  });

  test('exact multiples and empty files', () {
    expect(planChunks(60, 30), hasLength(2));
    final empty = planChunks(0, 30);
    expect(empty.single.length, 0);
    expect(() => planChunks(1, 0), throwsArgumentError);
  });

  test('hasher agrees between bytes, stream and file', () async {
    final bytes = List<int>.generate(1000, (i) => i % 251);
    final fromBytes = Hasher.ofBytes(bytes);
    final fromStream = await Hasher.ofStream(Stream.value(bytes));
    expect(fromStream, fromBytes);
    expect(fromBytes, hasLength(64));
  });
}
