import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recipe.dart';
import '../models/brew_step.dart';
import 'brew_result_screen.dart';
import '../viewmodels/brewing_viewmodel.dart';
import '../widgets/brewing/brew_progress_timeline.dart';
import '../widgets/brewing/brew_timer_display.dart';

/// 抽出実行画面
///
/// タイマーとガイドを表示しながら、実際のドリップを行います。
/// ステップごとの実績時間を記録し、終了後に結果画面へ遷移します。
class BrewingScreen extends ConsumerWidget {
  final Recipe recipe;

  const BrewingScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = brewingViewModelProvider(recipe);
    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);

    // Navigation Listener
    ref.listen<BrewingState>(provider, (previous, next) {
      if (!next.isFinished &&
          previous?.isFinished == false &&
          next.result != null) {
        // Handle finish (edge case where isFinished logic might differ)
      }
      if (next.isFinished && next.result != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BrewResultScreen(result: next.result!),
          ),
        );
      }
    });

    final stepCount = recipe.steps.length;
    if (stepCount == 0) return const SizedBox();

    final safeIndex = state.currentStepIndex >= stepCount
        ? stepCount - 1
        : state.currentStepIndex;
    final currentStep = recipe.steps[safeIndex];

    // Determine Button State
    String mainButtonLabel;
    Color mainButtonColor;
    Color mainButtonFgColor;
    IconData? mainButtonIcon;

    if (!state.isRunning && state.elapsed.inMilliseconds == 0) {
      mainButtonLabel = 'Start';
      mainButtonColor = Colors.green;
      mainButtonFgColor = Colors.white;
      mainButtonIcon = Icons.play_arrow;
    } else if (state.currentStepIndex >= stepCount - 1) {
      mainButtonLabel = 'Finish';
      mainButtonColor = Colors.orange;
      mainButtonFgColor = Colors.white;
      mainButtonIcon = Icons.check;
    } else {
      mainButtonLabel = 'Next Step';
      mainButtonColor = Theme.of(context).colorScheme.primary;
      mainButtonFgColor = Colors.white;
      mainButtonIcon = null;
    }

    // Button Action
    void onMainButtonPressed() {
      if (!state.isRunning && state.elapsed.inMilliseconds == 0) {
        viewModel.startBrewing();
      } else if (state.currentStepIndex >= stepCount - 1) {
        viewModel.finishBrewing();
      } else {
        viewModel.nextStep();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        actions: [
          IconButton(
            icon: Icon(state.isRunning ? Icons.pause : Icons.play_arrow),
            onPressed: viewModel.togglePause,
            tooltip: state.isRunning ? 'Pause' : 'Resume',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Timer
            BrewTimerDisplay(elapsed: state.elapsed),
            const Spacer(flex: 1),

            // Main Info
            Column(
              children: [
                // Step Type Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStepColor(currentStep.type).withAlpha(51),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStepColor(currentStep.type)),
                  ),
                  child: Text(
                    currentStep.type.name.toUpperCase(),
                    style: TextStyle(
                      color: _getStepColor(currentStep.type),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Main Value (Water or Time)
                if (currentStep.type == BrewStepType.pour) ...[
                  Text(
                    '${state.currentStepTargetWater.toStringAsFixed(0)}ml',
                    style: const TextStyle(
                        fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Target Water',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ] else ...[
                  // Wait / Stir の場合は残り時間を強調してもいいが、
                  // とりあえずは「Wait」等を表示しつつ、上のTimerで時間はわかるので
                  // ここでは「あと何秒」を出すか、シンプルにアイコンを出すか。
                  // 設計通り「湯量」は出さない。
                  Icon(
                    currentStep.type == BrewStepType.stir
                        ? Icons.gesture
                        : Icons.timer,
                    size: 48,
                    color: _getStepColor(currentStep.type),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${currentStep.waitTime.inSeconds}sec',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],

                // Description
                if (currentStep.description != null &&
                    currentStep.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withAlpha(128)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 20, color: Colors.amber),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            currentStep.description!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Secondary Info & Next Step
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMiniStat('Step', '${safeIndex + 1}/$stepCount'),
                const SizedBox(width: 24),
                // Next Step Info
                if (safeIndex + 1 < stepCount) ...[
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(width: 24),
                  Column(
                    children: [
                      Text(
                        'NEXT',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(_getStepIcon(recipe.steps[safeIndex + 1].type),
                              size: 16, color: Colors.grey[700]),
                          const SizedBox(width: 4),
                          Text(
                            recipe.steps[safeIndex + 1].type.name.toUpperCase(),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),

            const Spacer(flex: 2),

            // Timeline Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: BrewProgressTimeline(
                recipe: recipe,
                elapsed: state.elapsed,
              ),
            ),
            const SizedBox(height: 40),

            // Main Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: onMainButtonPressed,
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

  Color _getStepColor(BrewStepType type) {
    switch (type) {
      case BrewStepType.pour:
        return Colors.blue; // or Theme primary
      case BrewStepType.wait:
        return Colors.orange;
      case BrewStepType.stir:
        return Colors.green;
    }
  }

  IconData _getStepIcon(BrewStepType type) {
    switch (type) {
      case BrewStepType.pour:
        return Icons.water_drop;
      case BrewStepType.wait:
        return Icons.timer;
      case BrewStepType.stir:
        return Icons.gesture;
    }
  }
}
