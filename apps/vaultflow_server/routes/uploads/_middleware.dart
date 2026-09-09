import 'package:dart_frog/dart_frog.dart';
import 'package:vaultflow_server/vaultflow_server.dart';

Handler middleware(Handler handler) => handler.use(authRequired());
