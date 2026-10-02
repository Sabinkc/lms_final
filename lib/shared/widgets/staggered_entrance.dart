import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Fades and lifts a list card into place when a list first appears, each
/// card a little later than the one above it (by its position on screen),
/// so the list "deals in" instead of popping. Only the cards present in the
/// list's first moments animate — cards scrolled into view later, or rebuilt
/// after a refresh, simply appear. Off when the system asks for reduced
/// motion.
class StaggeredEntrance extends StatefulWidget {
  final Widget child;

  const StaggeredEntrance({super.key, required this.child});

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

/// When each route's list first started dealing in.
final _firstEntranceAt = Expando<Duration>();

class _StaggeredEntranceState extends State<StaggeredEntrance> with SingleTickerProviderStateMixin {
  static const _window = Duration(milliseconds: 600);
  static const _maxDelay = 300;

  static const _fade = 380;

  // Created in initState, not lazily: a card that never animates would
  // otherwise first create it in dispose(), which throws.
  late final AnimationController _controller;
  Animation<double> _curve = const AlwaysStoppedAnimation(0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    final box = context.findRenderObject() as RenderBox?;
    // Frame time, not wall-clock time: it's what animations run on.
    final now = SchedulerBinding.instance.currentFrameTimeStamp;
    final first = route == null ? now : (_firstEntranceAt[route] ??= now);
    if (MediaQuery.disableAnimationsOf(context) || box == null || !box.hasSize || now - first > _window) {
      setState(() => _curve = const AlwaysStoppedAnimation(1));
      return;
    }
    final screenHeight = MediaQuery.sizeOf(context).height;
    final y = box.localToGlobal(Offset.zero).dy.clamp(0.0, screenHeight);
    final delay = (y / screenHeight * _maxDelay).round();
    // The delay is the start of the animation itself (an Interval), so no
    // timer is left running if the card goes away early.
    final total = delay + _fade;
    _controller.duration = Duration(milliseconds: total);
    setState(() {
      _curve = CurvedAnimation(
        parent: _controller,
        curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      );
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(offset: Offset(0, 18 * (1 - _curve.value)), child: child),
      ),
      child: widget.child,
    );
  }
}
