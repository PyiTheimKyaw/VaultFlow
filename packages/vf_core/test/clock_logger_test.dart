import 'package:test/test.dart';
import 'package:vf_core/vf_core.dart';

void main() {
  group('FakeClock', () {
    test('advances deterministically', () {
      final clock = FakeClock(DateTime.utc(2026))
        ..advance(const Duration(minutes: 5));
      expect(clock.now(), DateTime.utc(2026, 1, 1, 0, 5));
      clock.set(DateTime.utc(2030));
      expect(clock.now().year, 2030);
    });

    test('SystemClock is UTC', () {
      expect(const SystemClock().now().isUtc, isTrue);
    });
  });

  group('Logger', () {
    late MemoryLogSink sink;

    setUp(() {
      sink = MemoryLogSink(capacity: 2);
      Logger.sink = sink;
      Logger.minimumLevel = LogLevel.debug;
      Logger.now = () => DateTime.utc(2026, 9, 6);
    });

    tearDown(() {
      Logger.sink = const ConsoleLogSink();
      Logger.minimumLevel = LogLevel.debug;
      Logger.now = () => DateTime.now().toUtc();
    });

    test('drops records below the minimum level', () {
      const Logger('t').trace('hidden');
      expect(sink.records, isEmpty);
      const Logger('t').info('shown', fields: {'n': 1});
      expect(sink.records.single.toString(), contains('[t] shown n=1'));
    });

    test('memory sink keeps only the newest records', () {
      const log = Logger('t');
      log
        ..info('1')
        ..info('2')
        ..info('3');
      expect(sink.records.map((r) => r.message), ['2', '3']);
    });
  });
}
