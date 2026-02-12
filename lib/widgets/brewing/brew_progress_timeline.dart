import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../models/brew_step.dart';

class BrewProgressTimeline extends StatelessWidget {
  final Recipe recipe;
  final Duration elapsed;

  const BrewProgressTimeline({
    super.key,
    required this.recipe,
    required this.elapsed,
  });

  @override
  Widget build(BuildContext context) {
    final steps = recipe.steps;
    // Calculate total duration for sanity check
    final totalDuration = steps.fold(0, (sum, s) => sum + s.waitTime.inSeconds);
    if (totalDuration == 0) return const SizedBox();

    final elapsedSeconds = elapsed.inMilliseconds / 1000.0;
    double accumulatedTime = 0;

    return Row(
      children: steps.asMap().entries.map((entry) {
        final step = entry.value;
        final stepSeconds = step.waitTime.inSeconds.toDouble();

        // Avoid zero-width flex issues
        final flex = stepSeconds > 0 ? stepSeconds.toInt() : 1;

        final stepStart = accumulatedTime;
        final stepEnd = stepStart + stepSeconds;

        double value = 0.0;
        if (elapsedSeconds >= stepEnd) {
          value = 1.0;
        } else if (elapsedSeconds <= stepStart) {
          value = 0.0;
        } else {
          value = (elapsedSeconds - stepStart) / stepSeconds;
        }

        accumulatedTime += stepSeconds;

        Color stepColor;
        switch (step.type) {
          case BrewStepType.pour:
            stepColor = Theme.of(context).primaryColor;
            break;
          case BrewStepType.wait:
            stepColor = Colors.orange; // 待機はオレンジ
            break;
          case BrewStepType.stir:
            stepColor = Colors.green; // 攪拌は緑
            break;
        }

        return Expanded(
          flex: flex,
          child: Container(
            height: 12, // Thicker for visibility
            margin: const EdgeInsets.symmetric(horizontal: 1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[300], // 背景を少し薄く
                valueColor: AlwaysStoppedAnimation<Color>(stepColor),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
