import 'dart:convert';

import 'package:meta/meta.dart';

/// Severity of a log record, ordered from most to least verbose.
enum LogLevel {
  trace,
  debug,
  info,
  warning,
  error;

  bool operator >=(LogLevel other) => index >= other.index;
}

/// One structured log entry.
@immutable
final class LogRecord {
  const LogRecord({
    required this.level,
    required this.tag,
    required this.message,
    required this.time,
    this.error,
    this.stackTrace,
    this.fields = const {},
  });

  final LogLevel level;
  final String tag;
  final String message;
  final DateTime time;
  final Object? error;
  final StackTrace? stackTrace;

  /// Extra structured context (`{'op': 'push', 'count': 3}`).
  final Map<String, Object?> fields;

  @override
  String toString() {
    final buffer = StringBuffer()
      ..write(time.toIso8601String())
      ..write(' ')
      ..write(level.name.toUpperCase().padRight(7))
      ..write(' [')
      ..write(tag)
      ..write('] ')
      ..write(message);
    if (fields.isNotEmpty) {
      buffer
        ..write(' ')
        ..write(fields.entries.map((e) => '${e.key}=${e.value}').join(' '));
    }
    if (error != null) buffer.write('\n  error: $error');
    if (stackTrace != null) buffer.write('\n$stackTrace');
    return buffer.toString();
  }
}

/// Destination for log records.
abstract interface class LogSink {
  void write(LogRecord record);
}

/// Writes records with `print`; fine for development.
final class ConsoleLogSink implements LogSink {
  const ConsoleLogSink();

  @override
  void write(LogRecord record) {
    // Console output is the whole point of this sink.
    // ignore: avoid_print
    print(record);
  }
}

/// One JSON object per line, for log shippers (Loki, CloudWatch, Datadog).
final class JsonLogSink implements LogSink {
  const JsonLogSink({this.out = _printLine});

  final void Function(String line) out;

  static void _printLine(String line) {
    // Standard output is where log shippers read from.
    // ignore: avoid_print
    print(line);
  }

  static String encode(LogRecord record) => jsonEncode({
    'ts': record.time.toIso8601String(),
    'level': record.level.name,
    'tag': record.tag,
    'msg': record.message,
    if (record.fields.isNotEmpty)
      'fields': {for (final e in record.fields.entries) e.key: '${e.value}'},
    if (record.error != null) 'error': '${record.error}',
    if (record.stackTrace != null) 'stack': '${record.stackTrace}',
  });

  @override
  void write(LogRecord record) => out(encode(record));
}

/// Keeps records in memory; for tests and in-app debug screens.
final class MemoryLogSink implements LogSink {
  MemoryLogSink({this.capacity = 500});

  final int capacity;
  final List<LogRecord> _records = [];

  List<LogRecord> get records => List.unmodifiable(_records);

  @override
  void write(LogRecord record) {
    _records.add(record);
    if (_records.length > capacity) _records.removeAt(0);
  }

  void clear() => _records.clear();
}

/// Minimal structured logger. Create one per component with a [tag].
///
/// Global configuration ([Logger.sink], [Logger.minimumLevel]) is set once at
/// app or server start.
final class Logger {
  const Logger(this.tag);

  final String tag;

  /// Where records go. Defaults to the console.
  static LogSink sink = const ConsoleLogSink();

  /// Records below this level are dropped.
  static LogLevel minimumLevel = LogLevel.debug;

  /// Time source for records; overridable in tests.
  static DateTime Function() now = () => DateTime.now().toUtc();

  bool isEnabled(LogLevel level) => level >= minimumLevel;

  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> fields = const {},
  }) {
    if (!isEnabled(level)) return;
    sink.write(
      LogRecord(
        level: level,
        tag: tag,
        message: message,
        time: now(),
        error: error,
        stackTrace: stackTrace,
        fields: fields,
      ),
    );
  }

  void trace(String message, {Map<String, Object?> fields = const {}}) =>
      log(LogLevel.trace, message, fields: fields);

  void debug(String message, {Map<String, Object?> fields = const {}}) =>
      log(LogLevel.debug, message, fields: fields);

  void info(String message, {Map<String, Object?> fields = const {}}) =>
      log(LogLevel.info, message, fields: fields);

  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> fields = const {},
  }) => log(
    LogLevel.warning,
    message,
    error: error,
    stackTrace: stackTrace,
    fields: fields,
  );

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> fields = const {},
  }) => log(
    LogLevel.error,
    message,
    error: error,
    stackTrace: stackTrace,
    fields: fields,
  );
}
