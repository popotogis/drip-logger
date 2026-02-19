import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import '../models/recipe.dart';
import '../models/brew_step.dart';

// -----------------------------------------------------------------------------
// State definition
// -----------------------------------------------------------------------------
class PreBrewState {
  final Recipe baseRecipe; // 元のレシピ
  final Recipe tempRecipe; // 調整中のレシピ
  final bool maintainRatio; // 比率維持モードかどうか

  const PreBrewState({
    required this.baseRecipe,
    required this.tempRecipe,
    this.maintainRatio = true,
  });

  PreBrewState copyWith({
    Recipe? baseRecipe,
    Recipe? tempRecipe,
    bool? maintainRatio,
  }) {
    return PreBrewState(
      baseRecipe: baseRecipe ?? this.baseRecipe,
      tempRecipe: tempRecipe ?? this.tempRecipe,
      maintainRatio: maintainRatio ?? this.maintainRatio,
    );
  }
}

// -----------------------------------------------------------------------------
// Notifier definition
// -----------------------------------------------------------------------------
class PreBrewViewModel extends StateNotifier<PreBrewState> {
  // Arguments need to be passed in constructor
  PreBrewViewModel(Recipe recipe)
      : super(PreBrewState(baseRecipe: recipe, tempRecipe: recipe));

  void setMaintainRatio(bool value) {
    state = state.copyWith(maintainRatio: value);
  }

  void updateBeanWeight(double newWeight) {
    if (state.maintainRatio) {
      final scaled = state.tempRecipe.scaleToBeanWeight(newWeight);
      state = state.copyWith(tempRecipe: scaled);
    } else {
      final updated = state.tempRecipe.copyWith(beanWeightGrams: newWeight);
      state = state.copyWith(tempRecipe: updated);
    }
  }

  void updateStepWater(int index, double newWater) {
    final currentRecipe = state.tempRecipe;
    final newSteps = List<BrewStep>.from(currentRecipe.steps);

    if (index < 0 || index >= newSteps.length) return;

    newSteps[index] = BrewStep(
      waterAmount: newWater,
      waitTime: newSteps[index].waitTime,
    );

    // 総湯量も更新
    final newTotal = newSteps.fold(0.0, (sum, s) => sum + s.waterAmount);

    // 整合性を保つため、ステップと総量を更新
    final updated = currentRecipe.copyWith(
      steps: newSteps,
      totalWaterAmount: newTotal,
    );

    state = state.copyWith(tempRecipe: updated);
  }

  void updateStepWaitTime(int index, int newSeconds) {
    final currentRecipe = state.tempRecipe;
    final newSteps = List<BrewStep>.from(currentRecipe.steps);

    if (index < 0 || index >= newSteps.length) return;

    newSteps[index] = BrewStep(
      waterAmount: newSteps[index].waterAmount,
      waitTime: Duration(seconds: newSeconds),
    );

    final updated = currentRecipe.copyWith(steps: newSteps);
    state = state.copyWith(tempRecipe: updated);
  }

  void updateGrindSize(String val) {
    state =
        state.copyWith(tempRecipe: state.tempRecipe.copyWith(grindSize: val));
  }

  void updateTemperature(double? val) {
    state =
        state.copyWith(tempRecipe: state.tempRecipe.copyWith(temperature: val));
  }

  void updateGrinder(String val) {
    state = state.copyWith(tempRecipe: state.tempRecipe.copyWith(grinder: val));
  }

  void updateDripper(String val) {
    state = state.copyWith(tempRecipe: state.tempRecipe.copyWith(dripper: val));
  }

  void updateFilter(String val) {
    state = state.copyWith(tempRecipe: state.tempRecipe.copyWith(filter: val));
  }

  void updateNote(String val) {
    state = state.copyWith(tempRecipe: state.tempRecipe.copyWith(note: val));
  }

  /// 編集画面等でBaseRecipe自体が更新された場合に呼び出す
  void setBaseRecipe(Recipe newBase) {
    state = state.copyWith(
      baseRecipe: newBase,
      tempRecipe: newBase,
    );
  }
}

// -----------------------------------------------------------------------------
// Provider definition
// -----------------------------------------------------------------------------
final preBrewViewModelProvider = StateNotifierProvider.autoDispose
    .family<PreBrewViewModel, PreBrewState, Recipe>(
  (ref, recipe) => PreBrewViewModel(recipe),
);
