import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'progress_overlay.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../shared/widgets/brand_app_bar.dart';
import '../../shared/widgets/app_background.dart';

/// Navigation-target scaffolding only — proves the router/role-guard
/// actually works end to end. The real Login form and the four real
/// Dashboards are feature work (docs/implementation_backlog.md E1, and
/// each role's Dashboard task) deliberately not built in this foundation
/// pass. Delete this file once every screen it stands in for has a real
/// implementation.
///
/// The logout button below is the pattern every future screen should
/// follow: a widget calls a method on its feature's `ChangeNotifier`
/// (`context.read<AuthProvider>()`), never a repository or `ApiClient`
/// directly.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showLogout;

  /// Shortcut buttons to real feature screens that now exist even though
  /// this dashboard itself is still a placeholder (e.g. Phase B's "Manage
  /// Classes" from the still-placeholder Admin Dashboard). Label + tap
  /// handler pairs, rendered in order.
  final List<(String, VoidCallback)> links;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.showLogout = false,
    this.links = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: title),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                for (final (label, onTap) in links) ...[
                  const SizedBox(height: 12),
                  FilledButton(onPressed: onTap, child: Text(label)),
                ],
                if (showLogout) ...[
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () =>
                        runWithProgress(context, context.read<AuthProvider>().logout, message: 'Logging out…'),
                    child: const Text('Log out'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
