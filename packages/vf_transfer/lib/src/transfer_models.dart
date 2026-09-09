import 'package:meta/meta.dart';
import 'package:vf_database/vf_database.dart';

enum TransferKind {
  upload,
  download;

  static TransferKind parse(String value) => values.byName(value);
}

enum TransferState {
  queued,
  running,
  paused,
  failed,
  completed,
  cancelled;

  static TransferState parse(String value) => values.byName(value);

  bool get isTerminal => this == completed || this == cancelled;
}

/// Live throughput for a running transfer (not persisted).
@immutable
class TransferProgress {
  const TransferProgress({
    required this.sessionId,
    required this.bytesDone,
    required this.totalBytes,
    this.bytesPerSecond = 0,
  });

  final String sessionId;
  final int bytesDone;
  final int totalBytes;
  final double bytesPerSecond;

  double get fraction => totalBytes == 0 ? 1 : bytesDone / totalBytes;

  Duration? get eta => bytesPerSecond <= 0
      ? null
      : Duration(seconds: ((totalBytes - bytesDone) / bytesPerSecond).round());
}

/// Convenience view over a session row.
extension TransferSessionRowX on TransferSessionRow {
  TransferKind get transferKind => TransferKind.parse(kind);
  TransferState get transferState => TransferState.parse(state);
}
