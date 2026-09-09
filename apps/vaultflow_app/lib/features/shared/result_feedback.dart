import 'package:flutter/material.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_domain/vf_domain.dart';

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

/// Feedback for a batch of imports: one success line, or the first failure.
void reportImport(BuildContext context, List<Result<Document>> results) {
  if (results.isEmpty) return;
  final failures = results.where((r) => r.isErr).toList();
  if (failures.isEmpty) {
    reportResult(
      context,
      okVoid,
      successMessage: results.length == 1
          ? 'Imported ${results.single.getOrThrow().name}'
          : 'Imported ${results.length} files',
    );
  } else {
    reportResult(context, failures.first);
  }
}

/// Feedback for a batch move/delete: "[verb] N items" or the first failure.
void reportBatch(
  BuildContext context,
  Result<int> result, {
  required String verb,
}) {
  switch (result) {
    case Ok(:final value):
      reportResult(
        context,
        okVoid,
        successMessage: value == 1 ? '$verb 1 item' : '$verb $value items',
      );
    case Err():
      reportResult(context, result);
  }
}
