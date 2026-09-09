import 'package:meta/meta.dart';

@immutable
class ChunkPlan {
  const ChunkPlan({
    required this.index,
    required this.offset,
    required this.length,
  });

  final int index;
  final int offset;
  final int length;

  int get end => offset + length;
}

/// Splits [totalBytes] into fixed [chunkSize] pieces; the last one is
/// shorter. A zero-byte file is one empty chunk so the protocol still has a
/// part to complete.
List<ChunkPlan> planChunks(int totalBytes, int chunkSize) {
  if (chunkSize <= 0) throw ArgumentError.value(chunkSize, 'chunkSize');
  if (totalBytes < 0) throw ArgumentError.value(totalBytes, 'totalBytes');
  if (totalBytes == 0) return const [ChunkPlan(index: 0, offset: 0, length: 0)];
  final plans = <ChunkPlan>[];
  var offset = 0;
  var index = 0;
  while (offset < totalBytes) {
    final length = (totalBytes - offset).clamp(0, chunkSize);
    plans.add(ChunkPlan(index: index, offset: offset, length: length));
    offset += length;
    index++;
  }
  return plans;
}
