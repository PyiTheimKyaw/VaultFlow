import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/vaultflow_server.dart';

/// Bearer auth everywhere, except that `GET /documents/{id}/content` may
/// instead carry a signed download token in the query string (browser
/// downloads cannot set headers).
Handler middleware(Handler handler) => handler.use(authOrDownloadToken());
