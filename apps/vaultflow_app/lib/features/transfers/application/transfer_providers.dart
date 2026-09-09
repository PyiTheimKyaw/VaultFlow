import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/features/vault/application/document_importer.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_transfer/vf_transfer.dart';

part 'transfer_providers.g.dart';

/// Created once per process; `main` calls `recover()` so transfers that
/// were running when the app died pick up where they stopped.
@Riverpod(keepAlive: true)
TransferEngine transferEngine(Ref ref) {
  final engine = TransferEngine(
    db: ref.watch(databaseProvider),
    api: ref.watch(apiClientProvider),
    cacheRoot: ref.watch(cacheDirectoryProvider).cacheRoot,
  );
  ref.onDispose(engine.dispose);
  return engine;
}

@riverpod
Stream<List<TransferSessionRow>> transferSessions(Ref ref) =>
    ref.watch(transferEngineProvider).watchSessions();

/// Live throughput per running session.
@riverpod
Stream<Map<String, TransferProgress>> transferProgress(Ref ref) {
  final engine = ref.watch(transferEngineProvider);
  final controller = StreamController<Map<String, TransferProgress>>();
  void push() => controller.add(engine.progress.value);
  engine.progress.addListener(push);
  push();
  ref.onDispose(() {
    engine.progress.removeListener(push);
    unawaited(controller.close());
  });
  return controller.stream;
}

/// Document name/size for each session (sessions store only ids).
@riverpod
Future<Map<String, DocumentRow>> transferDocuments(Ref ref) async {
  final sessions = await ref.watch(transferSessionsProvider.future);
  final dao = ref.watch(databaseProvider).documentsDao;
  final map = <String, DocumentRow>{};
  for (final id in sessions.map((s) => s.documentId).toSet()) {
    final row = await dao.getById(id);
    if (row != null) map[id] = row;
  }
  return map;
}

/// Bytes the server did not need because the content already existed.
@riverpod
Future<int> dedupeSavedBytes(Ref ref) async {
  ref.watch(transferSessionsProvider);
  final raw = await ref
      .watch(databaseProvider)
      .settingsDao
      .getSyncState('dedupe_saved_bytes');
  return int.tryParse(raw ?? '') ?? 0;
}
