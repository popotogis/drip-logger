import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import '../models/recipe.dart';
import '../models/brew_result.dart';
import '../models/brew_step.dart';
import '../repositories/brew_result_repository.dart';
import '../repositories/recipe_repository.dart';

// -----------------------------------------------------------------------------
// State definition
// -----------------------------------------------------------------------------
class BrewingState {
  final Recipe recipe;
  final Duration elapsed;
  final int currentStepIndex;
  final List<BrewResultStep> resultSteps;
  final bool isRunning; // Timer is active
  final bool isFinished; // Brewing completed
  final BrewResult? result; // The final result object

  const BrewingState({
    required this.recipe,
    this.elapsed = Duration.zero,
    this.currentStepIndex = 0,
    this.resultSteps = const [],
    this.isRunning = false,
    this.isFinished = false,
    this.result,
  });

  BrewingState copyWith({
    Recipe? recipe,
    Duration? elapsed,
    int? currentStepIndex,
    List<BrewResultStep>? resultSteps,
    bool? isRunning,
    bool? isFinished,
    BrewResult? result,
  }) {
    return BrewingState(
      recipe: recipe ?? this.recipe,
      elapsed: elapsed ?? this.elapsed,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      resultSteps: resultSteps ?? this.resultSteps,
      isRunning: isRunning ?? this.isRunning,
      isFinished: isFinished ?? this.isFinished,
      result: result ?? this.result,
    );
  }

  double get currentStepTargetWater {
    double total = 0;
    for (int i = 0; i <= currentStepIndex && i < recipe.steps.length; i++) {
      total += recipe.steps[i].waterAmount;
    }
    return total;
  }
}

// -----------------------------------------------------------------------------
// Notifier definition
// -----------------------------------------------------------------------------
class BrewingViewModel extends StateNotifier<BrewingState> {
  final Ref _ref;
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();
  DateTime? _brewStartTime;
  Duration _lastSplitTime = Duration.zero;

  BrewingViewModel(this._ref, Recipe recipe)
      : super(BrewingState(recipe: recipe)) {
    // ref.onDispose to cancel timer
    _ref.onDispose(() {
      _timer?.cancel();
      _stopwatch.stop();
    });
  }

  void startBrewing() {
    if (state.isRunning) return;

    _brewStartTime = DateTime.now();
    // Update last used time
    _ref.read(recipeRepositoryProvider).updateLastUsed(state.recipe.id);

    _startTimer();
  }

  void _startTimer() {
    _stopwatch.start();
    state = state.copyWith(isRunning: true);

    // Update every 30ms (approx 30fps)
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      // In StateNotifier, we check mounted to prevent updates after dispose?
      // StateNotifier automatically handles dispose check usually?
      // If disposed, calling state= throws.
      // Ref.onDispose cancels timer, so it should be safe.
      if (mounted) {
        state = state.copyWith(elapsed: _stopwatch.elapsed);
      }
    });
  }

  void stopTimer() {
    _stopwatch.stop();
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void togglePause() {
    if (_stopwatch.isRunning) {
      stopTimer();
    } else {
      _startTimer();
    }
  }

  void nextStep() {
    if (!_stopwatch.isRunning) {
      _startTimer();
    }

    final currentElapsed = _stopwatch.elapsed;
    final stepDuration = currentElapsed - _lastSplitTime;

    final step = BrewResultStep(
      stepIndex: state.currentStepIndex,
      plannedTime: state.recipe.steps[state.currentStepIndex].waitTime,
      actualTime: stepDuration,
      waterAmount: state.recipe.steps[state.currentStepIndex].waterAmount,
    );

    final newResults = [...state.resultSteps, step];

    _lastSplitTime = currentElapsed;

    state = state.copyWith(
      resultSteps: newResults,
      currentStepIndex: state.currentStepIndex + 1,
    );
  }

  Future<void> finishBrewing() async {
    stopTimer();

    final result = BrewResult(
      id: DateTime.now().toString(),
      recipe: state.recipe,
      brewedAt: _brewStartTime ?? DateTime.now(),
      steps: state.resultSteps,
      totalTime: _stopwatch.elapsed,
    );

    // Save to DB
    await _ref.read(brewResultRepositoryProvider).addResult(result);

    state = state.copyWith(
      isFinished: true,
      result: result,
    );
  }
}

// -----------------------------------------------------------------------------
// Provider definition
// -----------------------------------------------------------------------------
final brewingViewModelProvider = StateNotifierProvider.autoDispose
    .family<BrewingViewModel, BrewingState, Recipe>(
  (ref, recipe) => BrewingViewModel(ref, recipe),
);
