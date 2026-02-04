import 'package:drip_logger/models/brew_step.dart';
import 'package:drip_logger/models/recipe.dart';
import 'package:drip_logger/viewmodels/pre_brew_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Test Data
  final baseRecipe = Recipe(
    id: 'test_1',
    name: 'Base Recipe',
    beanWeightGrams: 15.0,
    grindSize: 'Medium',
    totalWaterAmount: 225.0,
    steps: [
      BrewStep(waterAmount: 45.0, waitTime: const Duration(seconds: 45)),
      BrewStep(waterAmount: 180.0, waitTime: const Duration(seconds: 0)),
    ],
  );

  group('PreBrewViewModel Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    PreBrewViewModel getViewModel() {
      // Initialize provider with baseRecipe
      container.listen(
        preBrewViewModelProvider(baseRecipe),
        (_, __) {},
        fireImmediately: true,
      );
      return container.read(preBrewViewModelProvider(baseRecipe).notifier);
    }

    PreBrewState getState() {
      return container.read(preBrewViewModelProvider(baseRecipe));
    }

    test('Initial state reflects base recipe', () {
      final state = getState();
      expect(state.baseRecipe, baseRecipe);
      expect(state.tempRecipe, baseRecipe);
      expect(state.maintainRatio, true);
    });

    test('Update Bean Weight scales water when maintainRatio is true', () {
      final viewModel = getViewModel();

      // Change bean from 15g to 30g (Double)
      viewModel.updateBeanWeight(30.0);

      final state = getState();
      expect(state.tempRecipe.beanWeightGrams, 30.0);
      expect(state.tempRecipe.totalWaterAmount, 450.0); // 225 * 2
      expect(state.tempRecipe.steps[0].waterAmount, 90.0); // 45 * 2
    });

    test('Update Bean Weight does NOT scale water when maintainRatio is false',
        () {
      final viewModel = getViewModel();
      viewModel.setMaintainRatio(false);

      // Change bean from 15g to 30g
      viewModel.updateBeanWeight(30.0);

      final state = getState();
      expect(state.tempRecipe.beanWeightGrams, 30.0);
      expect(state.tempRecipe.totalWaterAmount, 225.0); // Unchanged
    });

    test('Update Step Water recalculates total water', () {
      final viewModel = getViewModel();

      // Change first step water from 45.0 to 95.0 (+50)
      viewModel.updateStepWater(0, 95.0);

      final state = getState();
      expect(state.tempRecipe.steps[0].waterAmount, 95.0);
      // original total 225.0 -> new total 275.0
      expect(state.tempRecipe.totalWaterAmount, 275.0);
    });

    test('Update Step Wait Time does not affect water', () {
      final viewModel = getViewModel();

      viewModel.updateStepWaitTime(0, 60);

      final state = getState();
      expect(state.tempRecipe.steps[0].waitTime.inSeconds, 60);
      expect(state.tempRecipe.totalWaterAmount, 225.0);
    });

    test('Editing other parameters updates tempRecipe', () {
      final viewModel = getViewModel();

      viewModel.updateGrinder('Comandante');
      viewModel.updateNote('Good taste');

      final state = getState();
      expect(state.tempRecipe.grinder, 'Comandante');
      expect(state.tempRecipe.note, 'Good taste');
      // Base recipe should be untouched
      expect(state.baseRecipe.grinder, isNull);
    });
  });
}
