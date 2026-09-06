import 'dart:convert';

import 'package:test/test.dart';
import 'package:vf_protocol/vf_protocol.dart';

void main() {
  final now = DateTime.utc(2026, 9, 6, 12);

  group('entity DTOs', () {
    test('FolderDto round-trips with snake_case keys', () {
      final dto = FolderDto(
        id: 'f1',
        name: 'Docs',
        version: 3,
        createdAt: now,
        updatedAt: now,
        parentId: 'root',
      );
      final json = dto.toJson();
      expect(json['parent_id'], 'root');
      expect(json['created_at'], now.toIso8601String());
      expect(json.containsKey('deleted_at'), isFalse);
      expect(
        FolderDto.fromJson(
          jsonDecode(jsonEncode(json)) as Map<String, Object?>,
        ),
        dto,
      );
    });

    test('DocumentDto and NoteDto round-trip', () {
      final doc = DocumentDto(
        id: 'd1',
        folderId: 'f1',
        name: 'a.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 12,
        sha256: 'ab',
        version: 1,
        createdAt: now,
        updatedAt: now,
      );
      expect(DocumentDto.fromJson(doc.toJson()), doc);
      final note = NoteDto(
        id: 'n1',
        folderId: 'f1',
        title: 't',
        body: 'b',
        version: 0,
        createdAt: now,
        updatedAt: now,
        deletedAt: now,
      );
      expect(NoteDto.fromJson(note.toJson()), note);
      expect(note.toJson()['deleted_at'], isNotNull);
    });
  });

  group('sync DTOs', () {
    test('PushRequest serialises enums as snake_case strings', () {
      const request = PushRequest(
        deviceId: 'dev',
        ops: [
          SyncOpRequest(
            clientOpId: 'op1',
            entityType: EntityType.note,
            entityId: 'n1',
            op: SyncOp.update,
            baseVersion: 2,
            payload: {'title': 'x'},
          ),
          SyncOpRequest(
            clientOpId: 'op2',
            entityType: EntityType.folder,
            entityId: 'f1',
            op: SyncOp.delete,
            baseVersion: 1,
          ),
        ],
      );
      final json = request.toJson();
      final ops = json['ops']! as List<Object?>;
      final first = ops.first! as Map<String, Object?>;
      expect(first['entity_type'], 'note');
      expect(first['op'], 'update');
      expect(first['base_version'], 2);
      expect((ops[1]! as Map<String, Object?>)['payload'], isEmpty);
      expect(PushRequest.fromJson(json), request);
    });

    test('PushResponse carries conflict snapshots', () {
      const response = PushResponse(
        results: [
          SyncOpResult(
            clientOpId: 'op1',
            status: SyncOpStatus.applied,
            newVersion: 3,
          ),
          SyncOpResult(
            clientOpId: 'op2',
            status: SyncOpStatus.conflict,
            remote: {'title': 'theirs'},
            remoteVersion: 4,
          ),
        ],
      );
      final decoded = PushResponse.fromJson(response.toJson());
      expect(decoded, response);
      expect(decoded.results[1].remote, {'title': 'theirs'});
    });

    test('ChangesResponse round-trips', () {
      final response = ChangesResponse(
        changes: [
          ChangeDto(
            seq: 10,
            entityType: EntityType.document,
            entityId: 'd1',
            op: SyncOp.create,
            version: 1,
            deviceId: 'other',
            createdAt: now,
            payload: {'name': 'a'},
          ),
        ],
        nextCursor: 10,
        hasMore: false,
      );
      expect(ChangesResponse.fromJson(response.toJson()), response);
    });
  });

  group('transfer DTOs', () {
    test('UploadSessionResponse dedup and session shapes', () {
      const dedup = UploadSessionResponse(dedup: true, storageKey: 'k');
      expect(UploadSessionResponse.fromJson(dedup.toJson()), dedup);
      final session = UploadSessionResponse(
        uploadId: 'u1',
        chunkSize: vfDefaultChunkSize,
        expiresAt: now,
      );
      final decoded = UploadSessionResponse.fromJson(session.toJson());
      expect(decoded.dedup, isFalse);
      expect(decoded.chunkSize, 5 * 1024 * 1024);
    });

    test('UploadSessionStatus keeps received chunk list', () {
      final status = UploadSessionStatus(
        uploadId: 'u1',
        state: UploadSessionState.active,
        totalBytes: 100,
        chunkSize: 10,
        receivedChunks: [0, 2, 5],
        expiresAt: now,
      );
      final json = status.toJson();
      expect(json['state'], 'active');
      expect(UploadSessionStatus.fromJson(json), status);
    });
  });

  group('auth DTOs', () {
    test('AuthTokens round-trips', () {
      const tokens = AuthTokens(
        accessToken: 'a',
        refreshToken: 'r',
        deviceId: 'd',
        userId: 'u',
        expiresIn: 900,
      );
      expect(AuthTokens.fromJson(tokens.toJson()), tokens);
      expect(tokens.toJson()['access_token'], 'a');
    });
  });

  group('errors', () {
    test('ApiError envelope', () {
      const error = ApiError(
        code: ApiErrorCode.tokenExpired,
        message: 'expired',
        details: {'at': 1},
      );
      final envelope = error.toEnvelope();
      final inner = envelope['error']! as Map<String, Object?>;
      expect(inner['code'], 'token_expired');
      expect(ApiError.fromEnvelope(envelope), error);
    });

    test('ApiErrorCode maps to HTTP status and tolerates unknown codes', () {
      expect(ApiErrorCode.notFound.httpStatus, 404);
      expect(ApiErrorCode.rateLimited.httpStatus, 429);
      expect(ApiErrorCode.fromWire('email_taken'), ApiErrorCode.emailTaken);
      expect(ApiErrorCode.fromWire('something_new'), ApiErrorCode.internal);
      expect(ApiErrorCode.fromWire(null), ApiErrorCode.internal);
    });
  });

  group('ApiPaths', () {
    test('builds parameterised paths', () {
      expect(ApiPaths.uploadChunk('u1', 3), '/uploads/u1/chunks/3');
      expect(ApiPaths.uploadComplete('u1'), '/uploads/u1/complete');
      expect(ApiPaths.documentContent('d1'), '/documents/d1/content');
    });
  });

  group('enums', () {
    test('fromWire parses and rejects', () {
      expect(EntityType.fromWire('note'), EntityType.note);
      expect(() => EntityType.fromWire('x'), throwsArgumentError);
      expect(SyncOp.fromWire('move'), SyncOp.move);
      expect(() => SyncOp.fromWire('x'), throwsArgumentError);
    });
  });
}
