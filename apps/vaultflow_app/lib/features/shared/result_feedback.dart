import 'package:flutter/material.dart';
import 'package:vf_core/vf_core.dart';

/// Shows a snackbar for a failed [Result]; returns whether it succeeded.
bool reportResult<T>(
  BuildContext context,
  Result<T> result, {
  String? successMessage,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  switch (result) {
    case Ok():
      if (successMessage != null) {
        messenger?.showSnackBar(SnackBar(content: Text(successMessage)));
      }
      return true;
    case Err(:final failure):
      messenger?.showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return false;
  }
}
