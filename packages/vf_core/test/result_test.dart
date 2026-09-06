import 'package:test/test.dart';
import 'package:vf_core/vf_core.dart';

void main() {
  group('Result', () {
    test('ok exposes value and maps', () {
      const result = Result.ok(2);
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, 2);
      expect(result.map((v) => v * 3), const Ok(6));
      expect(result.when(ok: (v) => 'v$v', err: (_) => 'e'), 'v2');
    });

    test('err short-circuits map and flatMap', () {
      const failure = NetworkFailure('offline');
      const result = Result<int>.err(failure);
      expect(result.isErr, isTrue);
      expect(result.failureOrNull, failure);
      expect(result.map((v) => v * 3).failureOrNull, failure);
      expect(result.flatMap((v) => Ok('$v')).failureOrNull, failure);
      expect(result.getOrElse((_) => -1), -1);
      expect(result.getOrThrow, throwsA(failure));
    });

    test('guard converts thrown errors to UnexpectedFailure', () async {
      final result = await Result.guard<int>(() => throw StateError('boom'));
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull!.cause, isA<StateError>());
    });

    test('guard passes a thrown Failure through unchanged', () async {
      const failure = AuthFailure('expired');
      final result = await Result.guard<int>(() => throw failure);
      expect(result.failureOrNull, same(failure));
    });

    test('guard uses onError mapper', () {
      final result = Result.guardSync<int>(
        () => throw const FormatException('bad'),
        onError: (e, _) => ValidationFailure(e.toString(), field: 'x'),
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('equality', () {
      expect(const Ok(1), const Ok(1));
      expect(const Ok(1), isNot(const Ok(2)));
      expect(okVoid.isOk, isTrue);
    });
  });
}
