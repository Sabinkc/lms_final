import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/readable_color.dart';

/// Restyled 2026-09-12 to match the reference design's branded look (logo,
/// "Welcome Back" hero, pill-shaped inputs) — same [AuthProvider] wiring as
/// before, purely a visual pass. Deliberately does **not** add a "Forgot
/// password" link or a QR-login option: neither has a real implementation
/// anywhere in this app (`AuthRepository`'s doc comment confirms forgot-
/// password is a real backend endpoint this client never wired up, and
/// there is no QR-scan feature at all) — matching every other screen this
/// pass touched, the visual language is copied, not UI for features that
/// don't exist.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const pillRadius = BorderRadius.all(Radius.circular(28));

    return Scaffold(
      body: Stack(
        children: [
          Positioned(top: -60, left: -60, child: _decorativeBlob(AppColors.warning.withValues(alpha: 0.18), 180)),
          Positioned(bottom: -80, right: -80, child: _decorativeBlob(AppColors.primary.withValues(alpha: 0.16), 220)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 24),
                        Container(
                          width: 96,
                          height: 96,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          text: TextSpan(
                            style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                            children: [
                              TextSpan(
                                text: 'Clouds',
                                style: TextStyle(color: scheme.onSurface),
                              ),
                              TextSpan(
                                text: 'LMS',
                                style: TextStyle(color: context.readable(AppColors.primary)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'LEARN  •  MANAGE  •  GROW',
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Welcome Back',
                            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Sign in to continue your account.',
                            style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: const OutlineInputBorder(borderRadius: pillRadius),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: const OutlineInputBorder(borderRadius: pillRadius),
                          ),
                          obscureText: _obscurePassword,
                          onSubmitted: (_) => authProvider.isSubmitting ? null : _submit(),
                        ),
                        const SizedBox(height: 24),
                        if (authProvider.lastError != null) ...[
                          Text(authProvider.lastError!.message, style: TextStyle(color: scheme.error)),
                          // A ValidationException may carry field-level messages
                          // beyond its top-level `.message` (docs/api_spec.md §2's
                          // `errors` map) — show them too when present, rather than
                          // silently dropping the more specific guidance.
                          for (final fieldError in _fieldErrorsOf(authProvider.lastError))
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('• $fieldError', style: TextStyle(color: scheme.error, fontSize: 13)),
                            ),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              shape: const RoundedRectangleBorder(borderRadius: pillRadius),
                            ),
                            onPressed: authProvider.isSubmitting ? null : _submit,
                            icon: authProvider.isSubmitting
                                ? SizedBox(
                                    height: 16,
                                    width: 16,
                                    // The button is disabled (pale) while submitting.
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  )
                                : const Icon(Icons.login),
                            label: Text(authProvider.isSubmitting ? 'Logging in...' : 'Log In'),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorativeBlob(Color color, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  void _submit() {
    context.read<AuthProvider>().login(email: _emailController.text.trim(), password: _passwordController.text);
  }

  Iterable<String> _fieldErrorsOf(AppException? error) =>
      error is ValidationException ? error.fieldErrors.values.expand((messages) => messages) : const [];
}
