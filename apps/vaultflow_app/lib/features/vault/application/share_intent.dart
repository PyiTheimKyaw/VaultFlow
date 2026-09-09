import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vaultflow_app/features/vault/application/document_importer.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_domain/vf_domain.dart';

part 'share_intent.g.dart';

const _log = Logger('share');

/// A file handed to the app by the OS share sheet (Android). The platform
/// side has already copied it into the app cache.
typedef SharedFile = ({String name, String path});

/// Receives share-sheet files from the Android activity and imports them
/// into the vault root. iOS needs a share extension target, which is not
/// set up yet (see docs/platforms.md).
class ShareIntentImporter {
  ShareIntentImporter({
    required this.importer,
    required this.onImported,
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel('dev.vaultflow/share');

  final DocumentImporter importer;
  final void Function(List<Result<Document>> results) onImported;
  final MethodChannel _channel;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Starts listening and drains anything shared before start-up.
  Future<void> start() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'shared') await _import(_parse(call.arguments));
    });
    try {
      final pending = await _channel.invokeMethod<List<Object?>>('takePending');
      if (pending != null && pending.isNotEmpty) await _import(_parse(pending));
    } on MissingPluginException {
      // Not running inside MainActivity (tests, other platforms).
    }
  }

  void stop() => _channel.setMethodCallHandler(null);

  static List<SharedFile> _parse(Object? raw) => [
    for (final item in (raw as List?) ?? const [])
      if (item is Map) (name: '${item['name']}', path: '${item['path']}'),
  ];

  Future<void> _import(List<SharedFile> files) async {
    if (files.isEmpty) return;
    _log.info('share-sheet import', fields: {'files': files.length});
    final results = await importer.importAll([
      for (final f in files)
        ImportSource(name: f.name, bytes: File(f.path).openRead().cast()),
    ]);
    for (final f in files) {
      // The importer copied the bytes into the content-addressed cache.
      try {
        await File(f.path).delete();
      } on Object {
        // Best effort.
      }
    }
    onImported(results);
  }
}

/// Feedback from the last share-sheet import, for a snackbar.
@Riverpod(keepAlive: true)
class ShareImportResults extends _$ShareImportResults {
  @override
  List<Result<Document>> build() => const [];

  List<Result<Document>> get latest => state;
  set latest(List<Result<Document>> results) => state = results;
  void clear() => state = const [];
}

@Riverpod(keepAlive: true)
ShareIntentImporter? shareIntentImporter(Ref ref) {
  if (!ShareIntentImporter.isSupported) return null;
  final importer = ShareIntentImporter(
    importer: ref.watch(documentImporterProvider),
    onImported: (results) =>
        ref.read(shareImportResultsProvider.notifier).latest = results,
  );
  ref.onDispose(importer.stop);
  return importer;
}
