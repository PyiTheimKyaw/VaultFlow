import 'package:json_annotation/json_annotation.dart';

/// Outcome of a single pushed op.
@JsonEnum(fieldRename: FieldRename.snake)
enum SyncOpStatus {
  /// The op was applied; `new_version` is set.
  applied,

  /// The server's version differs from `base_version`; `remote` is set.
  conflict,

  /// The op is invalid (unknown entity, bad payload) and must be dropped.
  rejected,
}
