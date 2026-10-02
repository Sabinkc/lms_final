import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Makes its child sink slightly (to 96%) while a finger is on it, like a
/// physical button. Springs back as soon as the finger lifts — or moves
/// far enough to be a scroll rather than a tap. Doesn't change what a tap
/// does; the child keeps its own InkWell/onTap. Off for reduced motion.
class PressScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;

  const PressScale({super.key, required this.child, this.pressedScale = 0.96});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;
  Offset? _downAt;

  void _set(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return Listener(
      onPointerDown: (event) {
        _downAt = event.position;
        _set(true);
      },
      onPointerMove: (event) {
        final start = _downAt;
        if (start != null && (event.position - start).distance > kTouchSlop) _set(false);
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
