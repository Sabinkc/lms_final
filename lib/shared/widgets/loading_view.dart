import 'package:flutter/material.dart';

import 'skeleton.dart';

/// Generic loading state, reused across every feature: pulsing card-shaped
/// skeletons where the content will appear (docs/screens.md's convention)
/// rather than a lone spinner. [message] is read out by screen readers.
class LoadingView extends StatelessWidget {
  final String? message;

  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(label: message ?? 'Loading', liveRegion: true, child: const SkeletonCardList());
  }
}
