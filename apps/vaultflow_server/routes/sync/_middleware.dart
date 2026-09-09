import 'package:dart_frog/dart_frog.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:vaultflow_server/vaultflow_server.dart';

Handler middleware(Handler handler) =>
    handler.use(authRequired()).use(fromShelfMiddleware(_unbuffered));

/// `dart:io`'s HttpResponse buffers small writes, which would hold back
/// server-sent events until the buffer fills. shelf honours this context key
/// and turns buffering off for the response.
shelf.Handler _unbuffered(shelf.Handler inner) => (request) async {
  final response = await inner(request);
  if (!request.url.path.endsWith('events')) return response;
  return response.change(context: {'shelf.io.buffer_output': false});
};
