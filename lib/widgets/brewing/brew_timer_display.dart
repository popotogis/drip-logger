import 'package:flutter/material.dart';
import 'dart:ui'; // For FontFeature

class BrewTimerDisplay extends StatelessWidget {
  final Duration elapsed;

  const BrewTimerDisplay({super.key, required this.elapsed});

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(elapsed),
      style: const TextStyle(
        fontSize: 90,
        fontWeight: FontWeight.w200, // Thin font
        letterSpacing: -2.0,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    final milliseconds = (d.inMilliseconds.remainder(1000) ~/ 100).toString();
    return '$minutes:$seconds.$milliseconds';
  }
}
