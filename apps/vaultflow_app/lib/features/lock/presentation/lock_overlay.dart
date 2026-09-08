import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vf_security/vf_security.dart';
import 'package:vf_ui/vf_ui.dart';

/// Sits above the router. Draws a privacy cover while the app is inactive
/// and the full lock screen while the vault is locked, so no route can
/// leak content and the URL is preserved on web.
class LockOverlay extends ConsumerWidget {
  const LockOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appLockControllerProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isLocked) {
          return LockScreen(controller: controller);
        }
        if (controller.isObscured) {
          return const _PrivacyCover();
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// Forwards lifecycle transitions to the lock controller.
class LockLifecycle extends ConsumerStatefulWidget {
  const LockLifecycle({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LockLifecycle> createState() => _LockLifecycleState();
}

class _LockLifecycleState extends ConsumerState<LockLifecycle> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onStateChange: (state) =>
          ref.read(appLockControllerProvider).handleLifecycle(state),
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _PrivacyCover extends StatelessWidget {
  const _PrivacyCover();

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('privacy-cover'),
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Icon(
          Icons.lock_outline,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// PIN pad with optional biometric shortcut.
class LockScreen extends StatefulWidget {
  const LockScreen({required this.controller, super.key});

  final AppLockController controller;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _entry = '';
  String? _error;
  DateTime? _lockedUntil;
  Timer? _countdown;
  bool _busy = false;
  bool _promptedBiometrics = false;

  @override
  void initState() {
    super.initState();
    // Offer biometrics right away when enabled, like a banking app.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometrics());
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  Future<void> _tryBiometrics() async {
    if (_promptedBiometrics || !widget.controller.canUseBiometrics) return;
    _promptedBiometrics = true;
    await widget.controller.unlockWithBiometrics();
  }

  Future<void> _submit() async {
    if (_busy || _entry.length < PinVault.minLength) return;
    setState(() => _busy = true);
    final result = await widget.controller.unlockWithPin(_entry);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _entry = '';
      switch (result) {
        case PinOk():
          _error = null;
        case PinWrong(:final remainingAttempts):
          _error = remainingAttempts == 1
              ? 'Wrong PIN. 1 attempt left.'
              : 'Wrong PIN. $remainingAttempts attempts left.';
        case PinLockedOut(:final until):
          _lockedUntil = until;
          _startCountdown();
      }
    });
  }

  void _startCountdown() {
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_lockedUntil == null ||
          !_lockedUntil!.isAfter(widget.controller.clock.now())) {
        _countdown?.cancel();
        setState(() {
          _lockedUntil = null;
          _error = null;
        });
      } else {
        setState(() {});
      }
    });
  }

  void _press(String digit) {
    if (_busy || _lockedUntil != null) return;
    if (_entry.length >= PinVault.maxLength) return;
    setState(() {
      _entry += digit;
      _error = null;
    });
    if (_entry.length == PinVault.maxLength) unawaited(_submit());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lockedUntil = _lockedUntil;
    final remaining = lockedUntil?.difference(widget.controller.clock.now());
    return Material(
      key: const Key('lock-screen'),
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Padding(
              padding: VfSpacing.pagePadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: VfSpacing.xxxl,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: VfSpacing.md),
                  Text('Vault locked', style: theme.textTheme.titleLarge),
                  const SizedBox(height: VfSpacing.sm),
                  Text(
                    remaining != null && !remaining.isNegative
                        ? 'Too many attempts. Try again in '
                              '${remaining.inSeconds + 1}s.'
                        : (_error ?? 'Enter your PIN'),
                    key: const Key('lock-message'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _error != null || remaining != null
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: VfSpacing.lg),
                  _Dots(count: _entry.length),
                  const SizedBox(height: VfSpacing.lg),
                  _PinPad(
                    enabled: !_busy && lockedUntil == null,
                    onDigit: _press,
                    onBackspace: () => setState(
                      () => _entry = _entry.isEmpty
                          ? ''
                          : _entry.substring(0, _entry.length - 1),
                    ),
                    onSubmit: _submit,
                    biometrics: widget.controller.canUseBiometrics
                        ? _tryBiometricsAgain
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _tryBiometricsAgain() async {
    _promptedBiometrics = false;
    await _tryBiometrics();
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      key: const Key('pin-dots'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < PinVault.maxLength; i++)
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: VfSpacing.xs),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < count ? scheme.primary : scheme.outlineVariant,
            ),
          ),
      ],
    );
  }
}

class _PinPad extends StatelessWidget {
  const _PinPad({
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
    this.biometrics,
  });

  final bool enabled;
  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final VoidCallback? biometrics;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onTap, IconData? icon, Key? k}) =>
        SizedBox(
          width: 72,
          height: 56,
          child: OutlinedButton(
            key: k ?? Key('pin-$label'),
            onPressed: enabled ? onTap : null,
            child: icon != null
                ? Icon(icon)
                : Text(label, style: Theme.of(context).textTheme.titleLarge),
          ),
        );
    return Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: VfSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [for (final d in row) key(d, onTap: () => onDigit(d))],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (biometrics == null)
              const SizedBox(width: 72, height: 56)
            else
              key(
                'bio',
                icon: Icons.fingerprint,
                onTap: biometrics,
                k: const Key('pin-biometrics'),
              ),
            key('0', onTap: () => onDigit('0')),
            key('back', icon: Icons.backspace_outlined, onTap: onBackspace),
          ],
        ),
        const SizedBox(height: VfSpacing.md),
        FilledButton(
          key: const Key('pin-submit'),
          onPressed: enabled ? onSubmit : null,
          child: const Text('Unlock'),
        ),
      ],
    );
  }
}
