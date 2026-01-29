import 'package:flutter/material.dart';
import 'dart:async';
// for FontFeature
import '../models/recipe.dart';
import '../models/brew_result.dart';
import 'brew_result_screen.dart';

import '../repositories/recipe_repository.dart';

/// 抽出実行画面
///
/// タイマーとガイドを表示しながら、実際のドリップを行います。
/// ステップごとの実績時間を記録し、終了後に結果画面へ遷移します。
class BrewingScreen extends StatefulWidget {
  final Recipe recipe;

  const BrewingScreen({super.key, required this.recipe});

  @override
  State<BrewingScreen> createState() => _BrewingScreenState();
}

class _BrewingScreenState extends State<BrewingScreen> {
  // Timer State
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();

  // Recording State
  final List<BrewResultStep> _resultSteps = [];
  DateTime? _brewStartTime;
  Duration _lastSplitTime = Duration.zero;

  // Step State
  int _currentStepIndex = 0;

  double get _currentStepTargetWater {
    double total = 0;
    for (int i = 0; i <= _currentStepIndex; i++) {
      total += widget.recipe.steps[i].waterAmount;
    }
    return total;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _onMainActionButtonPressed() {
    if (!_stopwatch.isRunning && _elapsed.inMilliseconds == 0) {
      _startBrewing();
      return;
    }

    if (_currentStepIndex >= widget.recipe.steps.length - 1) {
      _finishBrewing();
      return;
    }

    _nextStep();
  }

  void _startBrewing() {
    _brewStartTime = DateTime.now();
    RecipeRepository().updateLastUsed(widget.recipe.id);
    _startTimer();
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (mounted) setState(() {});
    });
    setState(() {});
  }

  void _stopTimer() {
    _stopwatch.stop();
    _timer?.cancel();
    setState(() {});
  }

  void _togglePause() {
    if (_stopwatch.isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  Duration get _elapsed => _stopwatch.elapsed;

  void _nextStep() {
    if (!_stopwatch.isRunning) {
      _startTimer();
    }

    final currentElapsed = _stopwatch.elapsed;
    final stepDuration = currentElapsed - _lastSplitTime;

    _resultSteps.add(BrewResultStep(
      stepIndex: _currentStepIndex,
      plannedTime: widget.recipe.steps[_currentStepIndex].waitTime,
      actualTime: stepDuration,
      waterAmount: widget.recipe.steps[_currentStepIndex].waterAmount,
    ));

    _lastSplitTime = currentElapsed;

    setState(() {
      _currentStepIndex++;
    });
  }

  void _finishBrewing() {
    _stopTimer();

    final result = BrewResult(
      id: DateTime.now().toString(),
      recipe: widget.recipe,
      brewedAt: _brewStartTime ?? DateTime.now(),
      steps: _resultSteps,
      totalTime: _elapsed,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BrewResultScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepCount = widget.recipe.steps.length;
    if (stepCount == 0) return const SizedBox();

    final safeIndex =
        _currentStepIndex >= stepCount ? stepCount - 1 : _currentStepIndex;
    final currentStep = widget.recipe.steps[safeIndex];

    String mainButtonLabel;
    Color mainButtonColor;
    Color mainButtonFgColor;
    IconData? mainButtonIcon;

    if (!_stopwatch.isRunning && _elapsed.inMilliseconds == 0) {
      mainButtonLabel = 'Start';
      mainButtonColor = Colors.green;
      mainButtonFgColor = Colors.white;
      mainButtonIcon = Icons.play_arrow;
    } else if (_currentStepIndex >= stepCount - 1) {
      mainButtonLabel = 'Finish';
      mainButtonColor = Colors.orange;
      mainButtonFgColor = Colors.white;
      mainButtonIcon = Icons.check;
    } else {
      mainButtonLabel = 'Next Step';
      mainButtonColor = Theme.of(context).colorScheme.primary; // Tint Color
      mainButtonFgColor = Colors.white;
      mainButtonIcon = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.name),
        actions: [
          IconButton(
            icon: Icon(_stopwatch.isRunning ? Icons.pause : Icons.play_arrow),
            onPressed: _togglePause,
            tooltip: _stopwatch.isRunning ? 'Pause' : 'Resume',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Timer
            Text(
              _formatDuration(_elapsed),
              style: const TextStyle(
                fontSize: 90,
                fontWeight: FontWeight.w200, // Thin font
                letterSpacing: -2.0,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(flex: 1),

            // Main Info
            Column(
              children: [
                Text(
                  '${_currentStepTargetWater.toStringAsFixed(0)}ml',
                  style: const TextStyle(
                      fontSize: 48, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Target Water',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Secondary Info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMiniStat('Step', '${safeIndex + 1}/$stepCount'),
                const SizedBox(width: 40),
                _buildMiniStat('Wait', '${currentStep.waitTime.inSeconds}s'),
              ],
            ),

            const Spacer(flex: 2),

            // Timeline Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Builder(builder: (context) {
                final steps = widget.recipe.steps;
                // Calculate total duration for sanity check, though not strictly needed for Flex
                final totalDuration =
                    steps.fold(0, (sum, s) => sum + s.waitTime.inSeconds);
                if (totalDuration == 0) return const SizedBox();

                final elapsedSeconds = _elapsed.inMilliseconds / 1000.0;
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

                    return Expanded(
                      flex: flex,
                      child: Container(
                        height: 12, // Thicker for visibility
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: value,
                            backgroundColor: Colors.grey[400],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ),
            const SizedBox(height: 40),

            // Main Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _onMainActionButtonPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: mainButtonColor,
                    foregroundColor: mainButtonFgColor,
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (mainButtonIcon != null) ...[
                        Icon(mainButtonIcon),
                        const SizedBox(width: 8)
                      ],
                      Text(mainButtonLabel),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    final milliseconds = (d.inMilliseconds.remainder(1000) ~/ 100).toString();
    return "$minutes:$seconds.$milliseconds";
  }
}
