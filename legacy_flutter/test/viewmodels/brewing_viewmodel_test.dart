import 'package:drip_logger/models/brew_result.dart';
import 'package:drip_logger/models/brew_step.dart';
import 'package:drip_logger/models/recipe.dart';
import 'package:drip_logger/repositories/brew_result_repository.dart';
import 'package:drip_logger/repositories/recipe_repository.dart';
import 'package:drip_logger/viewmodels/brewing_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// -----------------------------------------------------------------------------
// Fakes
// -----------------------------------------------------------------------------
class FakeBrewResultRepository implements BrewResultRepository {
  final List<BrewResult> results = [];

  @override
  Future<void> addResult(BrewResult result) async {
    results.add(result);
  }

  // Other methods are not used in ViewModel so we can implement them as placeholders or throws
  @override
  Future<void> deleteResult(String id) async => throw UnimplementedError();

  @override
  Future<List<BrewResult>> getAllResults() async => results;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRecipeRepository implements RecipeRepository {
  String? lastUpdatedId;

  @override
  Future<void> updateLastUsed(String id) async {
    lastUpdatedId = id;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final testRecipe = Recipe(
    id: 'test_id',
    name: 'Test Recipe',
    beanWeightGrams: 15.0,
    grindSize: 'Medium',
    totalWaterAmount: 100.0,
    steps: [
      BrewStep(waterAmount: 50.0, waitTime: const Duration(seconds: 1)),
      BrewStep(waterAmount: 50.0, waitTime: const Duration(seconds: 1)),
    ],
  );

  group('BrewingViewModel Tests', () {
    late ProviderContainer container;
    late FakeBrewResultRepository fakeResultRepo;
    late FakeRecipeRepository fakeRecipeRepo;

    setUp(() {
      fakeResultRepo = FakeBrewResultRepository();
      fakeRecipeRepo = FakeRecipeRepository();

      container = ProviderContainer(overrides: [
        brewResultRepositoryProvider.overrideWithValue(fakeResultRepo),
        recipeRepositoryProvider.overrideWithValue(fakeRecipeRepo),
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    BrewingViewModel getViewModel() {
      // Keep provider alive
      container.listen(
        brewingViewModelProvider(testRecipe),
        (_, __) {},
        fireImmediately: true,
      );
      return container.read(brewingViewModelProvider(testRecipe).notifier);
    }

    BrewingState getState() {
      return container.read(brewingViewModelProvider(testRecipe));
    }

    test('Initial state is correct', () {
      final state = getState();
      expect(state.recipe, testRecipe);
      expect(state.currentStepIndex, 0);
      expect(state.isRunning, false);
      expect(state.isFinished, false);
    });

    test('Start Brewing starts timer and updates recipe last used', () async {
      final viewModel = getViewModel();

      viewModel.startBrewing();

      final state = getState();
      expect(state.isRunning, true);
      expect(fakeRecipeRepo.lastUpdatedId, testRecipe.id);
    });

    test('Next Step records result step and advances index', () async {
      final viewModel = getViewModel();
      viewModel.startBrewing();

      // Wait a bit to simulate time passing (optional, but good for coverage)
      await Future.delayed(const Duration(milliseconds: 50));

      viewModel.nextStep();

      final state = getState();
      expect(state.currentStepIndex, 1);
      expect(state.resultSteps.length, 1);
      expect(state.resultSteps.first.waterAmount, 50.0);
    });

    test('Finish Brewing stops timer and saves result', () async {
      final viewModel = getViewModel();
      viewModel.startBrewing();
      viewModel.nextStep(); // Step 1 done

      await viewModel.finishBrewing();

      final state = getState();
      expect(state.isRunning, false);
      expect(state.isFinished, true);
      expect(state.result, isNotNull);

      // Verify saved to repo
      expect(fakeResultRepo.results.length, 1);
      expect(fakeResultRepo.results.first.recipe.id, testRecipe.id);
    });

    test('Toggle Pause works', () async {
      final viewModel = getViewModel();
      viewModel.startBrewing();
      expect(getState().isRunning, true);

      viewModel.togglePause();
      expect(getState().isRunning, false);

      viewModel.togglePause();
      expect(getState().isRunning, true);
    });
  });
}
