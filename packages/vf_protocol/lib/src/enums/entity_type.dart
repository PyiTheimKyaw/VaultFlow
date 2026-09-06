import 'package:json_annotation/json_annotation.dart';

/// Kinds of synced entities. Wire values are lowercase and stable.
@JsonEnum(fieldRename: FieldRename.snake)
enum EntityType {
  folder,
  document,
  note;

  /// Parses a wire value; throws [ArgumentError] on unknown input.
  static EntityType fromWire(String value) => values.firstWhere(
    (e) => e.name == value,
    orElse: () => throw ArgumentError.value(value, 'value', 'unknown entity'),
  );
}
