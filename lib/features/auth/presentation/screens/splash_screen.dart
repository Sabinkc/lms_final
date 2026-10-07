import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

/// docs/screens.md "Splash Screen": brand loading screen that checks a
/// stored session and routes accordingly. All the actual routing decision
/// lives in `AppRouter`'s redirect (reacting to `AuthProvider.status`) —
/// this screen only needs to exist as something to render while that
/// resolves; it makes no navigation calls itself.
///
/// Visual structure matches `docs/stitch_screens/cloudslms_splash_screen`'s
/// gradient hero mockup — colors are this app's own confirmed brand tokens
/// (`AppColors.primary`), not the mockup's invented palette.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Read, not watch — this screen doesn't need to rebuild on auth
    // changes, the router already reacts to them via refreshListenable.
    context.read<AuthProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, Color.lerp(AppColors.primary, Colors.black, 0.45)!],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 112,
                height: 112,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
                ),
                child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.cover),
              ),
              const SizedBox(height: 24),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Clouds',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: 'LMS',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Empowering Education',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
              ),
              const Spacer(),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(Colors.white)),
              ),
              const SizedBox(height: 12),
              Text(
                'Loading...',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
