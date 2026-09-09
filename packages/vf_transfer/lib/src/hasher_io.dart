import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

Future<String> hashFile(String path) => Isolate.run(() async {
  final digest = await sha256.bind(File(path).openRead()).first;
  return digest.toString();
});
