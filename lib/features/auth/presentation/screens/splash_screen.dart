import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/loading_view.dart';
import '../providers/auth_provider.dart';

/// docs/screens.md "Splash Screen": brand loading screen that checks a
/// stored session and routes accordingly. All the actual routing decision
/// lives in `AppRouter`'s redirect (reacting to `AuthProvider.status`) —
/// this screen only needs to exist as something to render while that
/// resolves; it makes no navigation calls itself.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Read, not watch — this screen doesn't need to rebuild on auth
    // changes, the router already reacts to them via refreshListenable.
    context.read<AuthProvider>();
    return const Scaffold(body: LoadingView(message: 'Loading...'));
  }
}
