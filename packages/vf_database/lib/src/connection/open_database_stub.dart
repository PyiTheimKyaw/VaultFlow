import 'package:vf_database/src/database.dart';

Future<VaultFlowDatabase> openDatabase({
  required String name,
  required Future<String> Function() keyLoader,
}) => throw UnsupportedError('No database implementation for this platform');
