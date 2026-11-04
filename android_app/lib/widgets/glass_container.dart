import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;
  final Color? color;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.65,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF1E1F29).withValues(alpha: opacity),
        borderRadius: radius,
        border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      ),
    );
  }
}
