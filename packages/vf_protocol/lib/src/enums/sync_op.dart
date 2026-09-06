import 'package:json_annotation/json_annotation.dart';

/// Mutation kinds carried by the outbox and the change feed.
@JsonEnum(fieldRename: FieldRename.snake)
enum SyncOp {
  create,
  update,
  delete,
  move;

  /// Parses a wire value; throws [ArgumentError] on unknown input.
  static SyncOp fromWire(String value) => values.firstWhere(
    (e) => e.name == value,
    orElse: () => throw ArgumentError.value(value, 'value', 'unknown op'),
  );
}
