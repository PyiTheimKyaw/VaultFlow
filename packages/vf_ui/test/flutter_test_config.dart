import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden images are generated on macOS (`flutter test --update-goldens`).
/// Text rasterisation differs between macOS and the Linux CI runner by far
/// more than a tolerance can absorb, so the pixel comparison is only
/// enforced on macOS. Elsewhere the golden is still rendered and compared,
/// and the difference is reported, but it does not fail the run; the layout
/// assertions in each golden test carry the cross-platform guarantee.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final current = goldenFileComparator;
  if (current is LocalFileComparator) {
    goldenFileComparator = _PlatformAwareGoldenComparator(
      Uri.parse('${current.basedir}placeholder_test.dart'),
      tolerance: 0.005,
      enforce: Platform.isMacOS,
    );
  }
  await testMain();
}

class _PlatformAwareGoldenComparator extends LocalFileComparator {
  _PlatformAwareGoldenComparator(
    super.testFile, {
    required this.tolerance,
    required this.enforce,
  });

  /// Fraction of differing pixels still accepted on the enforcing platform.
  final double tolerance;

  /// Whether a mismatch fails the test.
  final bool enforce;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) return true;
    if (!enforce) {
      debugPrint(
        'golden $golden differs by '
        '${(result.diffPercent * 100).toStringAsFixed(2)}% on '
        '${Platform.operatingSystem}; not enforced off macOS',
      );
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}
