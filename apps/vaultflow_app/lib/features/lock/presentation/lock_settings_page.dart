import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/features/shared/result_feedback.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_security/vf_security.dart';
import 'package:vf_ui/vf_ui.dart';

/// PIN, biometrics and auto-lock timeout.
class LockSettingsPage extends ConsumerWidget {
  const LockSettingsPage({super.key});

  Future<void> _setPin(
    BuildContext context,
    AppLockController controller,
  ) async {
    final pin = await showDialog<String>(
      context: context,
      builder: (_) => const _PinSetupDialog(),
    );
    if (pin == null || !context.mounted) return;
    final result = await Result.guard(() => controller.setPin(pin));
    if (context.mounted) {
      reportResult(context, result, successMessage: 'PIN set');
    }
  }

  Future<void> _removePin(
    BuildContext context,
    AppLockController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove PIN?'),
        content: const Text(
          'The vault will no longer lock when you leave the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('remove-pin-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await controller.removePin();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appLockControllerProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final settings = controller.settings;
        final hasPin = controller.hasPin;
        final biometrics = controller.biometricAvailability;
        return ListView(
          key: const Key('lock-settings'),
          padding: VfSpacing.pagePadding,
          children: [
            ListTile(
              key: const Key('lock-set-pin'),
              leading: const Icon(Icons.pin_outlined),
              title: Text(hasPin ? 'Change PIN' : 'Set a PIN'),
              subtitle: Text(
                hasPin
                    ? 'The vault locks when you leave the app.'
                    : 'Required before the vault can lock.',
              ),
              onTap: () => _setPin(context, controller),
            ),
            if (hasPin)
              ListTile(
                key: const Key('lock-remove-pin'),
                leading: const Icon(Icons.lock_open_outlined),
                title: const Text('Remove PIN'),
                onTap: () => _removePin(context, controller),
              ),
            const Divider(),
            SwitchListTile(
              key: const Key('lock-biometrics'),
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Unlock with biometrics'),
              subtitle: Text(switch (biometrics) {
                BiometricAvailability.available =>
                  hasPin
                      ? 'Face ID, Touch ID or fingerprint; PIN stays as fallback.'
                      : 'Set a PIN first.',
                BiometricAvailability.notEnrolled =>
                  'No biometrics enrolled on this device.',
                BiometricAvailability.unsupported =>
                  'Not available on this platform.',
              }),
              value: settings.biometricsEnabled,
              onChanged: hasPin && biometrics == BiometricAvailability.available
                  ? (v) => controller.updateSettings(
                      settings.copyWith(biometricsEnabled: v),
                    )
                  : null,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Lock after'),
              subtitle: const Text('Time in the background before locking'),
              trailing: DropdownButton<Duration>(
                key: const Key('lock-timeout'),
                value: settings.timeout,
                onChanged: hasPin
                    ? (d) => controller.updateSettings(
                        settings.copyWith(timeout: d),
                      )
                    : null,
                items: [
                  for (final d in LockSettings.timeoutChoices)
                    DropdownMenuItem(value: d, child: Text(_label(d))),
                ],
              ),
            ),
            const SizedBox(height: VfSpacing.lg),
            OutlinedButton.icon(
              key: const Key('lock-now'),
              onPressed: hasPin ? controller.lock : null,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Lock now'),
            ),
          ],
        );
      },
    );
  }

  static String _label(Duration d) => switch (d.inSeconds) {
    0 => 'Immediately',
    60 => '1 minute',
    300 => '5 minutes',
    900 => '15 minutes',
    3600 => '1 hour',
    _ => '${d.inMinutes} minutes',
  };
}

class _PinSetupDialog extends StatefulWidget {
  const _PinSetupDialog();

  @override
  State<_PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<_PinSetupDialog> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _first.text;
    if (pin.length < PinVault.minLength || pin.length > PinVault.maxLength) {
      setState(() => _error = 'Use 4 to 8 digits');
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      setState(() => _error = 'Digits only');
      return;
    }
    if (pin != _second.text) {
      setState(() => _error = 'PINs do not match');
      return;
    }
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set a PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('pin-first'),
            controller: _first,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: PinVault.maxLength,
            decoration: const InputDecoration(labelText: 'PIN'),
          ),
          TextField(
            key: const Key('pin-second'),
            controller: _second,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: PinVault.maxLength,
            decoration: InputDecoration(
              labelText: 'Confirm PIN',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('pin-save'),
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
