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
    var currentRecipe = state.tempRecipe;
    final newSteps = List<BrewStep>.from(currentRecipe.steps);

    if (index < 0 || index >= newSteps.length) return;

    final oldStep = newSteps[index];
    newSteps[index] = BrewStep(
      type: oldStep.type,
      waterAmount: newWater,
      waitTime: oldStep.waitTime,
      description: oldStep.description,
      uid: oldStep.uid,
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

    final oldStep = newSteps[index];
    newSteps[index] = BrewStep(
      type: oldStep.type,
      waterAmount: oldStep.waterAmount,
      waitTime: Duration(seconds: newSeconds),
      description: oldStep.description,
      uid: oldStep.uid,
    );

    final updated = currentRecipe.copyWith(steps: newSteps);
    state = state.copyWith(tempRecipe: updated);
  }

  void updateStepType(int index, BrewStepType newType) {
    final currentRecipe = state.tempRecipe;
    final newSteps = List<BrewStep>.from(currentRecipe.steps);

    if (index < 0 || index >= newSteps.length) return;

    final oldStep = newSteps[index];

    // wait/stir の場合は waterAmount を 0 にする
    final newWater =
        (newType == BrewStepType.wait || newType == BrewStepType.stir)
            ? 0.0
            : oldStep.waterAmount;

    newSteps[index] = BrewStep(
      type: newType,
      waterAmount: newWater,
      waitTime: oldStep.waitTime,
      description: oldStep.description,
      uid: oldStep.uid,
    );

    // 総湯量も再計算
    final newTotal = newSteps.fold(0.0, (sum, s) => sum + s.waterAmount);

    final updated = currentRecipe.copyWith(
      steps: newSteps,
      totalWaterAmount: newTotal,
    );
    state = state.copyWith(tempRecipe: updated);
  }

  void updateStepDescription(int index, String newDescription) {
    final currentRecipe = state.tempRecipe;
    final newSteps = List<BrewStep>.from(currentRecipe.steps);

    if (index < 0 || index >= newSteps.length) return;

    final oldStep = newSteps[index];
    newSteps[index] = BrewStep(
      type: oldStep.type,
      waterAmount: oldStep.waterAmount,
      waitTime: oldStep.waitTime,
      description: newDescription,
      uid: oldStep.uid,
    );

    final updated = currentRecipe.copyWith(steps: newSteps);
    state = state.copyWith(tempRecipe: updated);
  }

  void addStep() {
    final currentRecipe = state.tempRecipe;
    final newSteps = List<BrewStep>.from(currentRecipe.steps);

    newSteps.add(
      BrewStep(
        type: BrewStepType.pour,
        waterAmount: 0,
        waitTime: const Duration(seconds: 0),
      ),
    );

    // 総湯量も更新 (0なので変わらないが念のため)
    final newTotal = newSteps.fold(0.0, (sum, s) => sum + s.waterAmount);

    final updated = currentRecipe.copyWith(
      steps: newSteps,
      totalWaterAmount: newTotal,
    );
    state = state.copyWith(tempRecipe: updated);
  }

  void removeStep(int index) {
    final currentRecipe = state.tempRecipe;
    final newSteps = List<BrewStep>.from(currentRecipe.steps);

    if (index < 0 || index >= newSteps.length) return;

    newSteps.removeAt(index);

    // 総湯量も更新
    final newTotal = newSteps.fold(0.0, (sum, s) => sum + s.waterAmount);

    final updated = currentRecipe.copyWith(
      steps: newSteps,
      totalWaterAmount: newTotal,
    );
    state = state.copyWith(tempRecipe: updated);
  }

  void reorderSteps(int oldIndex, int newIndex) {
    // ReorderableListViewの仕様で、移動先が後方の場合はindexがずれるため補正
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final currentRecipe = state.tempRecipe;
    final newSteps = List<BrewStep>.from(currentRecipe.steps);

    if (oldIndex < 0 ||
        oldIndex >= newSteps.length ||
        newIndex < 0 ||
        newIndex >= newSteps.length) {
      return;
    }

    final item = newSteps.removeAt(oldIndex);
    newSteps.insert(newIndex, item);

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
