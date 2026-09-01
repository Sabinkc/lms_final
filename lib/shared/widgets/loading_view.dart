import 'package:flutter/material.dart';

/// Generic loading state, reused across every feature (docs/screens.md's
/// stated convention: skeleton placeholders matching the final layout, not
/// a blocking spinner — [message] is shown here only as a foundation-level
/// fallback until each screen has its own skeleton layout).
class LoadingView extends StatelessWidget {
  final String? message;

  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
