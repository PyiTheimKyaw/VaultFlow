import 'dart:convert';

import 'package:drift/drift.dart';

/// Stores a JSON object in a TEXT column.
class JsonMapConverter extends TypeConverter<Map<String, Object?>, String> {
  const JsonMapConverter();

  @override
  Map<String, Object?> fromSql(String fromDb) =>
      fromDb.isEmpty ? const {} : jsonDecode(fromDb) as Map<String, Object?>;

  @override
  String toSql(Map<String, Object?> value) => jsonEncode(value);
}
