import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/vaultflow_server.dart';

/// `GET /documents/{id}/content` with `Range` support (206 + ETag).
Future<Response> onRequest(RequestContext context, String id) async {
  final rejected = methodNotAllowed(context, {HttpMethod.get, HttpMethod.head});
  if (rejected != null) return rejected;
  final auth = context.read<AuthContext>();
  final ContentRange range;
  try {
    range = await context.read<ServerContext>().content.read(
      auth.userId,
      id,
      rangeHeader: context.request.headers['range'],
    );
  } on RangeNotSatisfiable {
    return Response(
      statusCode: 416,
      headers: {'Content-Range': 'bytes */*', 'Accept-Ranges': 'bytes'},
      body: '',
    );
  }
  final headers = {
    'Content-Type': range.mimeType,
    'Content-Length': '${range.length}',
    'Accept-Ranges': 'bytes',
    'ETag': '"${range.etag}"',
    'Cache-Control': 'private, max-age=0',
    if (range.isPartial)
      'Content-Range': 'bytes ${range.start}-${range.end}/${range.total}',
    // Signed-link requests come from a browser: make it save the file.
    if (auth.deviceId == downloadLinkDevice)
      'Content-Disposition': contentDisposition(range.fileName ?? id),
  };
  if (context.request.method == HttpMethod.head) {
    return Response(headers: headers, body: '');
  }
  return Response.stream(
    statusCode: range.isPartial ? 206 : 200,
    headers: headers,
    body: range.stream,
  );
}
