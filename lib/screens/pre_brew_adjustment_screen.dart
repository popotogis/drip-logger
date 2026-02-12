import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../models/recipe.dart';
import '../utils/recipe_sharer.dart';
import 'brewing_screen.dart';
import 'recipe_edit_screen.dart';
import '../repositories/recipe_repository.dart';
import '../viewmodels/pre_brew_viewmodel.dart';
import '../widgets/common/recipe_summary_card.dart';
import '../widgets/pre_brew/bean_weight_section.dart';
import '../widgets/pre_brew/parameter_edit_section.dart';
import '../widgets/pre_brew/step_edit_list.dart';

/// 抽出前調整画面
///
/// レシピを元に、その時の状況（豆の量や味の好み）に合わせて一時的にパラメータを変更します。
class PreBrewAdjustmentScreen extends ConsumerWidget {
  final Recipe recipe;

  // Form validation key
  static final _formKey = GlobalKey<FormState>();

  const PreBrewAdjustmentScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ViewModel provider (family)
    final provider = preBrewViewModelProvider(recipe);
    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjust Recipe'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  await _editOriginal(context, ref, state.baseRecipe, provider);
                  break;
                case 'share':
                  await _shareRecipe(context, state.baseRecipe);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Edit Original'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Header
              RecipeSummaryCard(recipe: state.tempRecipe),
              const SizedBox(height: 24),

              // Bean Weight Section
              BeanWeightSection(
                beanWeight: state.tempRecipe.beanWeightGrams,
                maintainRatio: state.maintainRatio,
                onWeightChanged: viewModel.updateBeanWeight,
                onMaintainRatioChanged: viewModel.setMaintainRatio,
              ),
              const SizedBox(height: 24),

              // Other Params
              ParameterEditSection(
                recipe: state.tempRecipe,
                onGrindSizeChanged: viewModel.updateGrindSize,
                onTemperatureChanged: viewModel.updateTemperature,
                onGrinderChanged: viewModel.updateGrinder,
                onDripperChanged: viewModel.updateDripper,
                onFilterChanged: viewModel.updateFilter,
              ),
              const SizedBox(height: 24),

              // Steps Section
              const Text(
                'STEPS (Adjust Water for Taste)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              StepEditList(
                steps: state.tempRecipe.steps,
                onWaterChanged: viewModel.updateStepWater,
                onWaitTimeChanged: viewModel.updateStepWaitTime,
                onTypeChanged: viewModel.updateStepType,
                onDescriptionChanged: viewModel.updateStepDescription,
                onAddStep: viewModel.addStep,
                onRemoveStep: viewModel.removeStep,
              ),

              const SizedBox(height: 24),

              // Note
              TextFormField(
                initialValue: state.tempRecipe.note ?? '',
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
                onChanged: viewModel.updateNote,
              ),

              const SizedBox(height: 40),

              // Start Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BrewingScreen(recipe: state.tempRecipe),
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Confirm & Start Brewing',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editOriginal(
    BuildContext context,
    WidgetRef ref,
    Recipe baseRecipe,
    dynamic provider,
  ) async {
    final updatedRecipe = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeEditScreen(recipe: baseRecipe),
      ),
    );

    if (updatedRecipe != null && updatedRecipe is Recipe) {
      // リポジトリに保存
      await ref.read(recipeRepositoryProvider).saveRecipe(updatedRecipe);

      // ViewModelの状態を更新
      ref.read(provider.notifier).setBaseRecipe(updatedRecipe);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Original recipe updated')),
        );
      }
    }
  }

  Future<void> _shareRecipe(BuildContext context, Recipe baseRecipe) async {
    // 共有するのは「元レシピ」か「調整後」か？
    // DetailScreenの代替機能としては「元レシピ」を共有すべき。
    final code = RecipeSharer.encode(baseRecipe);
    if (code.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: code));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe copied to clipboard!')),
        );
      }
    }
  }
}
