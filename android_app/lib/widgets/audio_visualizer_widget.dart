import 'dart:math';
import 'package:flutter/material.dart';

class AudioVisualizerWidget extends StatefulWidget {
  final bool isPlaying;
  final Color primaryColor;
  final Color secondaryColor;
  final int barCount;

  const AudioVisualizerWidget({
    super.key,
    required this.isPlaying,
    required this.primaryColor,
    required this.secondaryColor,
    this.barCount = 24,
  });

  @override
  State<AudioVisualizerWidget> createState() => _AudioVisualizerWidgetState();
}

class _AudioVisualizerWidgetState extends State<AudioVisualizerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _randomFactors = [];

  @override
  void initState() {
    super.initState();
    final random = Random(42);
    for (int i = 0; i < widget.barCount; i++) {
      _randomFactors.add(0.4 + random.nextDouble() * 0.6);
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addListener(() {
        if (mounted) setState(() {});
      });

    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AudioVisualizerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.animateTo(0.1, duration: const Duration(milliseconds: 300));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          final t = _controller.value;
          final phase = (index / widget.barCount) * pi;
          // Harmonic wave simulation
          final waveHeight = widget.isPlaying
              ? (sin(phase + t * 2 * pi).abs() * _randomFactors[index] * 18 + 4)
              : 3.5;

          final colorT = index / widget.barCount;
          final barColor = Color.lerp(widget.primaryColor, widget.secondaryColor, colorT) ??
              widget.primaryColor;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 3.2,
            height: waveHeight.clamp(3.0, 22.0),
            decoration: BoxDecoration(
              color: barColor.withValues(alpha: widget.isPlaying ? 0.9 : 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
