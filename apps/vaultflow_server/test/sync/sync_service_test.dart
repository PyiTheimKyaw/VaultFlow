import 'package:test/test.dart';
import 'package:vaultflow_server/vaultflow_server.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_protocol/vf_protocol.dart';

void main() {
  late InMemorySyncStore store;
  late SyncService service;
  late FakeClock clock;
  const user = 'user-1';
  const deviceA = 'device-a';
  const deviceB = 'device-b';
  final noteId = VfId.next();

  setUp(() {
    store = InMemorySyncStore();
    clock = FakeClock(DateTime.utc(2026, 9, 8, 10));
    service = SyncService(store: store, clock: clock);
  });

  Map<String, Object?> notePayload({
    String title = 'Hello',
    String body = '',
  }) => {
    'title': title,
    'body': body,
    'created_at': clock.now().toIso8601String(),
    'updated_at': clock.now().toIso8601String(),
  };

  SyncOpRequest op(
    SyncOp kind, {
    required int base,
    String id = '',
    Map<String, Object?> payload = const {},
    String clientOpId = '',
  }) => SyncOpRequest(
    clientOpId: clientOpId.isEmpty ? VfId.random() : clientOpId,
    entityType: EntityType.note,
    entityId: id.isEmpty ? noteId : id,
    op: kind,
    baseVersion: base,
    payload: payload,
  );

  Future<SyncOpResult> pushOne(String device, SyncOpRequest request) async {
    final response = await service.push(
      userId: user,
      deviceId: device,
      request: PushRequest(deviceId: device, ops: [request]),
    );
    return response.results.single;
  }

  test('create then update bump versions and append to the feed', () async {
    final created = await pushOne(
      deviceA,
      op(SyncOp.create, base: 0, payload: notePayload()),
    );
    expect(created.status, SyncOpStatus.applied);
    expect(created.newVersion, 1);

    final updated = await pushOne(
      deviceA,
      op(SyncOp.update, base: 1, payload: notePayload(title: 'Edited')),
    );
    expect(updated.newVersion, 2);

    final stored = await store.find(user, EntityType.note, noteId);
    expect(stored!.version, 2);
    expect(stored.snapshot['title'], 'Edited');
    expect(stored.snapshot['id'], noteId);
    expect(store.changes.map((c) => c.op), [SyncOp.create, SyncOp.update]);
  });

  test(
    'replaying a client_op_id returns the stored result without reapplying',
    () async {
      final request = op(
        SyncOp.create,
        base: 0,
        payload: notePayload(),
        clientOpId: 'op-1',
      );
      final first = await pushOne(deviceA, request);
      final second = await pushOne(deviceA, request);
      expect(second.toJson(), first.toJson());
      expect(store.changes, hasLength(1));
      expect((await store.find(user, EntityType.note, noteId))!.version, 1);
    },
  );

  test(
    'stale base_version is a conflict carrying the remote snapshot',
    () async {
      await pushOne(
        deviceA,
        op(SyncOp.create, base: 0, payload: notePayload()),
      );
      await pushOne(
        deviceA,
        op(SyncOp.update, base: 1, payload: notePayload(title: 'A2')),
      );

      final result = await pushOne(
        deviceB,
        op(SyncOp.update, base: 1, payload: notePayload(title: 'B2')),
      );
      expect(result.status, SyncOpStatus.conflict);
      expect(result.remoteVersion, 2);
      expect(result.remote!['title'], 'A2');
      // Nothing was applied.
      expect(
        (await store.find(user, EntityType.note, noteId))!.snapshot['title'],
        'A2',
      );
      expect(store.changes, hasLength(2));
    },
  );

  test('creating an entity that already exists is a conflict', () async {
    await pushOne(deviceA, op(SyncOp.create, base: 0, payload: notePayload()));
    final result = await pushOne(
      deviceB,
      op(SyncOp.create, base: 0, payload: notePayload()),
    );
    expect(result.status, SyncOpStatus.conflict);
    expect(result.remoteVersion, 1);
  });

  test('ops on unknown entities and bad payloads are rejected', () async {
    final unknown = await pushOne(
      deviceA,
      op(SyncOp.update, base: 1, payload: notePayload()),
    );
    expect(unknown.status, SyncOpStatus.rejected);

    final badId = await pushOne(
      deviceA,
      op(SyncOp.create, base: 0, id: 'not-a-uuid'),
    );
    expect(badId.status, SyncOpStatus.rejected);

    final badPayload = await pushOne(
      deviceA,
      op(SyncOp.create, base: 0, payload: {'title': 'no body'}),
    );
    expect(badPayload.status, SyncOpStatus.rejected);
    expect(badPayload.error, isNotEmpty);
    expect(store.changes, isEmpty);
  });

  test('move and delete derive from the current snapshot', () async {
    final folderId = VfId.next();
    await pushOne(deviceA, op(SyncOp.create, base: 0, payload: notePayload()));
    final moved = await pushOne(
      deviceA,
      op(SyncOp.move, base: 1, payload: {'folder_id': folderId}),
    );
    expect(moved.newVersion, 2);
    expect(
      (await store.find(user, EntityType.note, noteId))!.snapshot['folder_id'],
      folderId,
    );

    final badMove = await pushOne(
      deviceA,
      op(SyncOp.move, base: 2, payload: {'parent_id': 'x'}),
    );
    expect(badMove.status, SyncOpStatus.rejected);

    clock.advance(const Duration(minutes: 1));
    final deleted = await pushOne(deviceA, op(SyncOp.delete, base: 2));
    expect(deleted.newVersion, 3);
    final stored = await store.find(user, EntityType.note, noteId);
    expect(stored!.isDeleted, isTrue);
    expect(stored.snapshot['title'], 'Hello', reason: 'tombstone keeps data');
    expect(store.changes.last.payload['deleted_at'], isNotNull);
  });

  test('changes feed pages by seq and excludes the caller device', () async {
    for (var i = 0; i < 5; i++) {
      await pushOne(
        i.isEven ? deviceA : deviceB,
        op(
          SyncOp.create,
          base: 0,
          id: VfId.next(),
          payload: notePayload(title: 'n$i'),
        ),
      );
    }
    final page1 = await service.changes(userId: user, since: 0, limit: 2);
    expect(page1.changes.map((c) => c.seq), [1, 2]);
    expect(page1.hasMore, isTrue);
    expect(page1.nextCursor, 2);

    final page2 = await service.changes(
      userId: user,
      since: page1.nextCursor,
      limit: 2,
    );
    expect(page2.changes.map((c) => c.seq), [3, 4]);
    final page3 = await service.changes(
      userId: user,
      since: page2.nextCursor,
      limit: 2,
    );
    expect(page3.changes.map((c) => c.seq), [5]);
    expect(page3.hasMore, isFalse);
    expect(page3.nextCursor, 5);

    final onlyB = await service.changes(
      userId: user,
      since: 0,
      limit: 100,
      excludeDeviceId: deviceA,
    );
    expect(onlyB.changes.map((c) => c.deviceId).toSet(), {deviceB});
    expect(onlyB.changes.first.payload['title'], 'n1');

    final empty = await service.changes(userId: user, since: 5, limit: 10);
    expect(empty.changes, isEmpty);
    expect(empty.nextCursor, 5);
  });

  test("users cannot see or touch each other's entities", () async {
    await pushOne(deviceA, op(SyncOp.create, base: 0, payload: notePayload()));
    final other = await service.push(
      userId: 'user-2',
      deviceId: 'device-x',
      request: PushRequest(
        deviceId: 'device-x',
        ops: [
          op(SyncOp.update, base: 1, payload: notePayload(title: 'hijack')),
        ],
      ),
    );
    expect(other.results.single.status, SyncOpStatus.rejected);
    final feed = await service.changes(userId: 'user-2', since: 0, limit: 10);
    expect(feed.changes, isEmpty);
  });

  test('pushes over the op limit are refused', () async {
    final ops = List.generate(
      vfMaxPushOps + 1,
      (_) =>
          op(SyncOp.create, base: 0, id: VfId.next(), payload: notePayload()),
    );
    expect(
      () => service.push(
        userId: user,
        deviceId: deviceA,
        request: PushRequest(deviceId: deviceA, ops: ops),
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test(
    'simultaneous pushes from two devices yield one applied and one conflict',
    () async {
      await pushOne(
        deviceA,
        op(SyncOp.create, base: 0, payload: notePayload()),
      );
      // Both devices edit v1 and push at the same instant.
      final results = await Future.wait([
        pushOne(
          deviceA,
          op(SyncOp.update, base: 1, payload: notePayload(title: 'A')),
        ),
        pushOne(
          deviceB,
          op(SyncOp.update, base: 1, payload: notePayload(title: 'B')),
        ),
      ]);
      final statuses = results.map((r) => r.status).toList()
        ..sort((a, b) => a.index.compareTo(b.index));
      expect(statuses, [SyncOpStatus.applied, SyncOpStatus.conflict]);
      final stored = await store.find(user, EntityType.note, noteId);
      expect(stored!.version, 2);
      expect(store.changes, hasLength(2));
      final conflict = results.firstWhere(
        (r) => r.status == SyncOpStatus.conflict,
      );
      expect(conflict.remoteVersion, 2);
      expect(conflict.remote!['title'], isIn(['A', 'B']));
    },
  );
}
