import 'package:dart_frog/dart_frog.dart';

/// Root middleware: request logging and JSON error mapping.
///
/// Later phases add request ids, auth, and database providers here.
Handler middleware(Handler handler) {
  return handler.use(requestLogger());
}
