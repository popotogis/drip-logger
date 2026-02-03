import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drip_logger/services/database_service.dart';
import 'package:drip_logger/repositories/recipe_repository.dart';
import 'package:drip_logger/repositories/bean_repository.dart';
import 'package:drip_logger/repositories/brew_result_repository.dart';
import 'package:drip_logger/models/recipe.dart';
import 'package:drip_logger/models/bean.dart';
import 'package:drip_logger/models/brew_result.dart';
import 'package:drip_logger/models/brew_step.dart';

Future<void> generateDummyData(WidgetRef ref) async {
  // Clear all data
  await ref.read(databaseServiceProvider).clearAllData();

  final recipeRepo = ref.read(recipeRepositoryProvider);
  final beanRepo = ref.read(beanRepositoryProvider);
  final resultRepo = ref.read(brewResultRepositoryProvider);

  // 1. Recipes
  final recipes = [
    Recipe(
      id: 'r1',
      name: '4:6 Method',
      beanWeightGrams: 20,
      grindSize: 'Medium-Coarse',
      totalWaterAmount: 300,
      steps: [
        BrewStep(waterAmount: 60, waitTime: const Duration(seconds: 45)),
        BrewStep(waterAmount: 60, waitTime: const Duration(seconds: 45)),
        BrewStep(waterAmount: 60, waitTime: const Duration(seconds: 45)),
        BrewStep(waterAmount: 60, waitTime: const Duration(seconds: 45)),
        BrewStep(waterAmount: 60, waitTime: const Duration(seconds: 45)),
      ],
      note: 'Tetsu Kasuya method. Sweet and clean.',
      dripper: 'Hario V60',
      grinder: 'Comandante C40',
      lastUsed: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Recipe(
      id: 'r2',
      name: 'James Hoffmann Ultimate',
      beanWeightGrams: 30,
      grindSize: 'Medium',
      totalWaterAmount: 500,
      steps: [
        BrewStep(waterAmount: 60, waitTime: const Duration(seconds: 45)),
        BrewStep(waterAmount: 240, waitTime: const Duration(seconds: 75)),
        BrewStep(waterAmount: 200, waitTime: const Duration(seconds: 60)),
      ],
      note: 'Morning standard brew.',
      dripper: 'V60 02',
      grinder: 'Fellow Ode',
      lastUsed: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Recipe(
      id: 'r3',
      name: 'AeroPress Inverted',
      beanWeightGrams: 15,
      grindSize: 'Fine',
      totalWaterAmount: 200,
      steps: [
        BrewStep(waterAmount: 200, waitTime: const Duration(seconds: 120)),
      ],
      note: 'Strong body.',
      dripper: 'AeroPress',
      lastUsed: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  for (var r in recipes) {
    await recipeRepo.saveRecipe(r);
  }

  // 2. Beans
  final beans = [
    Bean(
      id: 'b1',
      name: 'Ethiopia Yirgacheffe Aricha',
      roaster: 'The Barn',
      roastLevel: 'Light',
      origin: 'Ethiopia',
      process: 'Natural',
      variety: 'Heirloom',
      roastDate: DateTime.now().subtract(const Duration(days: 10)),
      lastUsed: DateTime.now(),
    ),
    Bean(
      id: 'b2',
      name: 'Kenya AA',
      roaster: 'Tim Wendelboe',
      roastLevel: 'Light',
      origin: 'Kenya',
      process: 'Washed',
      variety: 'SL28',
      roastDate: DateTime.now().subtract(const Duration(days: 20)),
      lastUsed: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Bean(
      id: 'b3',
      name: 'Colombia Pink Bourbon',
      roaster: 'Sey Coffee',
      roastLevel: 'Medium-Light',
      origin: 'Colombia',
      process: 'Washed',
      variety: 'Pink Bourbon',
      roastDate: DateTime.now().subtract(const Duration(days: 5)),
      lastUsed: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  for (var b in beans) {
    await beanRepo.saveBean(b);
  }

  // 3. Brew Results
  final now = DateTime.now();
  final results = [
    BrewResult(
      id: 'br1',
      recipe: recipes[0],
      bean: beans[0],
      brewedAt: now.subtract(const Duration(hours: 2)),
      steps: recipes[0]
          .steps
          .map((s) => BrewResultStep(
                stepIndex: 0, // Simplified
                plannedTime: s.waitTime,
                actualTime: s.waitTime + const Duration(milliseconds: 500),
                waterAmount: s.waterAmount,
              ))
          .toList(),
      totalTime: const Duration(minutes: 3, seconds: 30),
      notes: 'Best cup of the month!',
    ),
    BrewResult(
      id: 'br2',
      recipe: recipes[1],
      bean: beans[1],
      brewedAt: now.subtract(const Duration(days: 1, hours: 8)),
      steps: [],
      totalTime: const Duration(minutes: 4),
      notes: 'A bit bitter. Coarsen grind next time.',
    ),
    BrewResult(
      id: 'br3',
      recipe: recipes[0],
      bean: beans[2],
      brewedAt: now.subtract(const Duration(days: 2, hours: 9)),
      steps: [],
      totalTime: const Duration(minutes: 3, seconds: 40),
      notes: 'Good body.',
    ),
    BrewResult(
      id: 'br4',
      recipe: recipes[2],
      bean: beans[1], // Kenya on AeroPress
      brewedAt: now.subtract(const Duration(days: 4)),
      steps: [],
      totalTime: const Duration(minutes: 2, seconds: 10),
      notes: 'Quick morning fix.',
    ),
  ];

  for (var res in results) {
    await resultRepo.addResult(res);
  }
}
