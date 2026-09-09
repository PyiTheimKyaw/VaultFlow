import 'dart:async';
import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/vaultflow_server.dart';
import 'package:vf_protocol/vf_protocol.dart';

/// `GET /sync/events`: server-sent events nudging the client to pull.
///
/// Emits `event: change` with the newest sequence whenever another device
/// appends to this user's change log (polled every 2 s per connection), a
/// `: ping` comment every 15 s, and closes after `eventsMaxAge` so clients
/// reconnect and idle connections never accumulate.
Future<Response> onRequest(RequestContext context) async {
  final rejected = methodNotAllowed(context, {HttpMethod.get});
  if (rejected != null) return rejected;
  final auth = context.read<AuthContext>();
  final server = context.read<ServerContext>();
  final query = context.request.uri.queryParameters;
  final excludeDevice = query['exclude_device'] ?? auth.deviceId;
  final poll = Duration(
    milliseconds: int.tryParse(query['poll_ms'] ?? '') ?? 2000,
  );
  final maxAge = server.config.eventsMaxAge;

  Stream<List<int>> body() async* {
    final started = server.clock.now();
    var lastSeq = (await server.syncStore.latestChange(auth.userId))?.seq ?? 0;
    yield utf8.encode('retry: 3000\n\n');
    var sincePing = Duration.zero;
    while (server.clock.now().difference(started) < maxAge) {
      await Future<void>.delayed(poll);
      sincePing += poll;
      final latest = await server.syncStore.latestChange(auth.userId);
      if (latest != null && latest.seq > lastSeq) {
        lastSeq = latest.seq;
        if (latest.deviceId != excludeDevice) {
          final data = jsonEncode(SyncEvent(seq: latest.seq).toJson());
          yield utf8.encode('event: change\ndata: $data\n\n');
          sincePing = Duration.zero;
        }
      }
      if (sincePing >= const Duration(seconds: 15)) {
        yield utf8.encode(': ping\n\n');
        sincePing = Duration.zero;
      }
    }
  }

  return Response.stream(
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'X-Accel-Buffering': 'no',
    },
    body: body(),
  );
}
