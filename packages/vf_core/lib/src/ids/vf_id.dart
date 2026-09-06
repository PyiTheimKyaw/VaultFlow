import 'package:uuid/uuid.dart';

/// Generates and validates the UUID v7 identifiers used for every entity.
///
/// v7 ids are time-ordered, which keeps SQLite/Postgres primary-key indexes
/// append-mostly and makes ids sortable by creation time without a separate
/// column. Ids are generated client-side so offline creates never wait for
/// the server.
abstract final class VfId {
  static const Uuid _uuid = Uuid();

  static final RegExp _pattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );

  /// Returns a new lowercase UUID v7 string.
  static String next() => _uuid.v7();

  /// Returns a new random (v4) UUID; used where ordering is undesirable, such
  /// as idempotency keys and refresh tokens.
  static String random() => _uuid.v4();

  /// Whether [value] is a well-formed lowercase UUID string of any version.
  static bool isValid(String value) => _pattern.hasMatch(value);

  /// Extracts the millisecond timestamp embedded in a v7 id, or `null` when
  /// [value] is not a v7 id.
  static DateTime? timestampOf(String value) {
    if (!isValid(value) || value[14] != '7') return null;
    final hex = value.substring(0, 8) + value.substring(9, 13);
    final millis = int.tryParse(hex, radix: 16);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }
}
