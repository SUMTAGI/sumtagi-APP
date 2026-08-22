import 'package:flutter/material.dart';

/// Drop-in replacement for `GestureDetector` on custom tappable widgets.
/// A bare `GestureDetector` gives no visual response until `onTap` fires on
/// release, which reads as unresponsive on real devices — this wraps the
/// child in a transparent `InkWell` so the press is highlighted immediately.
class TapFeedback extends StatelessWidget {
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;
  final Widget child;

  const TapFeedback({
    super.key,
    required this.onTap,
    this.borderRadius,
    this.customBorder,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: customBorder == null ? (borderRadius ?? BorderRadius.zero) : null,
        customBorder: customBorder,
        child: child,
      ),
    );
  }
}
