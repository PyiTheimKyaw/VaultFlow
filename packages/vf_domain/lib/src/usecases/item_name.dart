import 'package:vf_core/vf_core.dart';

/// Validation shared by every create/rename use case.
abstract final class ItemName {
  static const int maxLength = 255;
  static final RegExp _forbidden = RegExp(r'[\\/:*?"<>|\x00-\x1F]');

  /// Returns the trimmed name, or a [ValidationFailure].
  static Result<String> validate(String raw) {
    final name = raw.trim();
    if (name.isEmpty) {
      return const Err(
        ValidationFailure('Name cannot be empty', field: 'name'),
      );
    }
    if (name.length > maxLength) {
      return const Err(
        ValidationFailure('Name is too long (max 255)', field: 'name'),
      );
    }
    if (name == '.' || name == '..') {
      return const Err(ValidationFailure('Invalid name', field: 'name'));
    }
    if (_forbidden.hasMatch(name)) {
      return const Err(
        ValidationFailure(
          r'Name cannot contain \ / : * ? " < > |',
          field: 'name',
        ),
      );
    }
    return Ok(name);
  }
}
