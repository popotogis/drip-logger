import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recipe.dart';
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
                Text(
                  '${state.currentStepTargetWater.toStringAsFixed(0)}ml',
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
}
