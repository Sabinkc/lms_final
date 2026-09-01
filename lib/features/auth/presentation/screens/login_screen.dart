import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_exception.dart';
import '../providers/auth_provider.dart';

/// Structural scaffolding only — proves the auth flow (form → provider →
/// repository → router redirect) works end to end against the real backend.
/// The real login UI (design-system-accurate layout, "Forgot password"
/// link, inline validation copy per docs/screens.md) is Auth **feature**
/// work, not foundation.
///
/// Note what this screen does NOT do: no `ApiClient`/`Dio` import, no
/// `AuthRepository` import. It only ever talks to [AuthProvider].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('CloudsLMS')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                if (authProvider.lastError != null) ...[
                  Text(
                    authProvider.lastError!.message,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  // A ValidationException may carry field-level messages
                  // beyond its top-level `.message` (docs/api_spec.md §2's
                  // `errors` map) — show them too when present, rather than
                  // silently dropping the more specific guidance.
                  for (final fieldError in _fieldErrorsOf(authProvider.lastError))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '• $fieldError',
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  onPressed: authProvider.isSubmitting ? null : _submit,
                  child: authProvider.isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Log in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    context.read<AuthProvider>().login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  Iterable<String> _fieldErrorsOf(AppException? error) =>
      error is ValidationException ? error.fieldErrors.values.expand((messages) => messages) : const [];
}
