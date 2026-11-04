import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Smooth, Apple Music style animated heart favorite button with spring bounce and optimistic state
class AnimatedFavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onToggle;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const AnimatedFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onToggle,
    this.size = 23.0,
    this.activeColor = AppTheme.appleRed,
    this.inactiveColor = AppTheme.textSecondary,
  });

  @override
  State<AnimatedFavoriteButton> createState() => _AnimatedFavoriteButtonState();
}

class _AnimatedFavoriteButtonState extends State<AnimatedFavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    // Spring pop scale: 1.0 -> 1.45 -> 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.45)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.45, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(AnimatedFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite != oldWidget.isFavorite) {
      setState(() {
        _isFavorite = widget.isFavorite;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    setState(() {
      _isFavorite = !_isFavorite;
    });
    _controller.forward(from: 0.0);
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkResponse(
        onTap: _handleTap,
        radius: 22,
        splashColor: AppTheme.appleRed.withValues(alpha: 0.2),
        highlightColor: Colors.transparent,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Icon(
                _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                key: ValueKey<bool>(_isFavorite),
                color: _isFavorite ? widget.activeColor : widget.inactiveColor,
                size: widget.size,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
