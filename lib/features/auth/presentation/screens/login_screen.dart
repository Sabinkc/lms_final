import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/readable_color.dart';
import '../../../../shared/widgets/form_sheet.dart';
import '../providers/auth_provider.dart';

/// Matches the user's Canva login design #1 (2026-10-07): white page with
/// green + orange corner swooshes, logo + wordmark + tagline, "Welcome Back"
/// with an orange underline, outlined rounded fields, a solid green Log In
/// button and an orange "Forgot Password?" link. Same [AuthProvider] wiring
/// as before.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = context.readable(AppColors.primary);
    final ink = isDark ? scheme.onSurface : AppColors.ink;
    final muted = isDark ? scheme.onSurfaceVariant : AppColors.inkMuted;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBase : AppColors.surface,
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _CornerSwooshPainter())),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/logo_mark.png', width: 120, semanticLabel: 'CloudsLMS logo'),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Clouds',
                                style: TextStyle(color: ink),
                              ),
                              TextSpan(
                                text: 'LMS',
                                style: TextStyle(color: brand),
                              ),
                            ],
                          ),
                          style: textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.05,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _Tagline(style: textTheme.labelLarge?.copyWith(color: ink, letterSpacing: 1.2)),
                      const SizedBox(height: 36),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Welcome ',
                              style: TextStyle(color: ink),
                            ),
                            TextSpan(
                              text: 'Back',
                              style: TextStyle(color: brand),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to continue your account',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(color: muted),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 80,
                        height: 3,
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(height: 28),
                      _OutlinedField(
                        controller: _emailController,
                        hint: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      _OutlinedField(
                        controller: _passwordController,
                        hint: 'Password',
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => authProvider.isSubmitting ? null : _submit(),
                        suffix: IconButton(
                          tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: muted,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (authProvider.lastError != null) ...[
                        Text(
                          authProvider.lastError!.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.error),
                        ),
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
                      _LoginButton(
                        submitting: authProvider.isSubmitting,
                        onPressed: authProvider.isSubmitting ? null : _submit,
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPassword,
                          style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                          child: Text(
                            'Forgot Password?',
                            style: textTheme.bodyMedium?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    context.read<AuthProvider>().login(email: _emailController.text.trim(), password: _passwordController.text);
  }

  /// The app has no self-service reset flow yet (the backend's OTP
  /// endpoints aren't wired up — see `AuthRepository`), so point the user
  /// at whoever created their account.
  void _showForgotPassword() {
    showFormSheet<void>(
      context: context,
      builder: (sheetContext) => FormSheet(
        title: const Text('Forgot password?'),
        content: const Text('Please contact your school administrator. They can set a new password for your account.'),
        actions: [FilledButton(onPressed: () => Navigator.of(sheetContext).pop(), child: const Text('OK'))],
      ),
    );
  }

  Iterable<String> _fieldErrorsOf(AppException? error) =>
      error is ValidationException ? error.fieldErrors.values.expand((messages) => messages) : const [];
}

/// "Learn • Manage • Grow" with orange dots.
class _Tagline extends StatelessWidget {
  const _Tagline({required this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    Widget dot() => Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Learn', style: style),
        dot(),
        Text('Manage', style: style),
        dot(),
        Text('Grow', style: style),
      ],
    );
  }
}

/// Rounded rectangle with a thin brand-green outline (thicker when focused).
class _OutlinedField extends StatelessWidget {
  const _OutlinedField({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = context.readable(AppColors.primary);
    OutlineInputBorder outline(double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: brand, width: width),
    );

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? scheme.onSurfaceVariant : AppColors.inkMuted),
        filled: true,
        fillColor: isDark ? AppColors.darkElevated2 : AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: outline(1.2),
        enabledBorder: outline(1.2),
        focusedBorder: outline(2),
        suffixIcon: suffix,
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.submitting, required this.onPressed});

  final bool submitting;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.7),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        child: submitting
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  ),
                  SizedBox(width: 14),
                  Text('Logging in...'),
                ],
              )
            : const Text('Log In'),
      ),
    );
  }
}

/// The design's corner art: a green swoosh with a tapered orange ribbon
/// beside it (separated by a white gap) in the top-left and bottom-right
/// corners. Drawn in a 428-unit-wide space scaled by the screen width, with
/// the bottom shapes anchored to the bottom edge, so the corners keep the
/// design's proportions on any screen height.
class _CornerSwooshPainter extends CustomPainter {
  const _CornerSwooshPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 428;
    Offset top(double x, double y) => Offset(x * k, y * k);
    // Bottom shapes are written with y measured up from the bottom edge.
    Offset bottom(double x, double y) => Offset(x * k, size.height - y * k);

    Path shape(Offset Function(double, double) p, List<List<double>> cmds) {
      final path = Path();
      for (final c in cmds) {
        if (c.length == 2) {
          final o = p(c[0], c[1]);
          c == cmds.first ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
        } else {
          final a = p(c[0], c[1]), b = p(c[2], c[3]), e = p(c[4], c[5]);
          path.cubicTo(a.dx, a.dy, b.dx, b.dy, e.dx, e.dy);
        }
      }
      return path..close();
    }

    final green = Paint()..color = AppColors.primary;
    final orange = Paint()..color = AppColors.accent;

    // Top-left.
    canvas.drawPath(
      shape(top, [
        [0, 0],
        [132, 0],
        [96, 30, 52, 62, 0, 86],
      ]),
      green,
    );
    canvas.drawPath(
      shape(top, [
        [0, 94],
        [60, 70, 112, 36, 150, 0],
        [164, 0],
        [124, 44, 66, 82, 0, 104],
      ]),
      orange,
    );

    // Bottom-right.
    canvas.drawPath(
      shape(bottom, [
        [428, 0],
        [428, 100],
        [362, 92, 300, 56, 270, 0],
      ]),
      green,
    );
    canvas.drawPath(
      shape(bottom, [
        [428, 108],
        [356, 102, 292, 62, 258, 0],
        [230, 0],
        [270, 76, 344, 114, 428, 120],
      ]),
      orange,
    );
  }

  @override
  bool shouldRepaint(_CornerSwooshPainter oldDelegate) => false;
}
