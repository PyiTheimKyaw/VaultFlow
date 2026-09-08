import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultflow_app/app/di.dart';
import 'package:vaultflow_app/features/auth/application/session_controller.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_ui/vf_ui.dart';

enum _Mode { signIn, register }

/// Email + password sign in, with a toggle to create an account.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  _Mode _mode = _Mode.signIn;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final controller = ref.read(sessionControllerProvider.notifier);
    final result = _mode == _Mode.signIn
        ? await controller.signIn(email: _email.text, password: _password.text)
        : await controller.register(
            email: _email.text,
            password: _password.text,
          );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = switch (result) {
        Ok() => null,
        Err(:final failure) => switch (failure) {
          NetworkFailure() =>
            'Cannot reach the server at $apiBaseUrl. '
                'Check your connection.',
          _ => failure.message,
        },
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRegister = _mode == _Mode.register;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: VfSpacing.pagePadding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: VfSpacing.xxxl,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: VfSpacing.lg),
                    Text(
                      'VaultFlow',
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: VfSpacing.xs),
                    Text(
                      isRegister
                          ? 'Create your vault'
                          : 'Sign in to your vault',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: VfSpacing.xxl),
                    TextFormField(
                      key: const Key('login-email'),
                      controller: _email,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Enter a valid email'
                          : null,
                    ),
                    const SizedBox(height: VfSpacing.md),
                    TextFormField(
                      key: const Key('login-password'),
                      controller: _password,
                      enabled: !_busy,
                      obscureText: true,
                      autofillHints: [
                        if (isRegister)
                          AutofillHints.newPassword
                        else
                          AutofillHints.password,
                      ],
                      decoration: const InputDecoration(labelText: 'Password'),
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Enter your password';
                        }
                        if (isRegister && v.length < 8) {
                          return 'Use at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: VfSpacing.md),
                      Text(
                        _error!,
                        key: const Key('login-error'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: VfSpacing.xl),
                    FilledButton(
                      key: const Key('login-submit'),
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isRegister ? 'Create account' : 'Sign in'),
                    ),
                    const SizedBox(height: VfSpacing.sm),
                    TextButton(
                      key: const Key('login-toggle'),
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _mode = isRegister
                                  ? _Mode.signIn
                                  : _Mode.register;
                              _error = null;
                            }),
                      child: Text(
                        isRegister
                            ? 'Already have an account? Sign in'
                            : 'New here? Create an account',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
