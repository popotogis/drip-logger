import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recipe.dart';
import '../utils/recipe_sharer.dart';
import 'recipe_edit_screen.dart';
import 'pre_brew_adjustment_screen.dart';

/// レシピ詳細画面
///
/// レシピの内容（豆量、湯量、ステップなど）を表示し、編集や抽出開始（Brewing）への遷移を提供します。
class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe _recipe;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
  }

  Widget _buildGroupedSection({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool showDivider = true, bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 16)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey)),
            ],
          ),
        ),
        if (showDivider && !isLast)
          const Divider(height: 1, indent: 16, thickness: 0.5),
      ],
    );
  }

  String _calculateTotalTime() {
    int totalSeconds =
        _recipe.steps.fold(0, (sum, step) => sum + step.waitTime.inSeconds);
    final min = totalSeconds ~/ 60;
    final sec = totalSeconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        Navigator.pop(context, _recipe);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recipe'),
          actions: [
            TextButton(
              onPressed: () async {
                final updatedRecipe = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeEditScreen(recipe: _recipe),
                  ),
                );

                if (updatedRecipe != null && updatedRecipe is Recipe) {
                  setState(() {
                    _recipe = updatedRecipe;
                  });
                }
              },
              child: const Text('Edit', style: TextStyle(fontSize: 17)),
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
                final code = RecipeSharer.encode(_recipe);
                if (code.isNotEmpty) {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Recipe copied to clipboard!')),
                    );
                  }
                }
              },
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe Name - Large Title equivalent
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                child: Text(
                  _recipe.name,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // Section 1: Ingredients
              const Padding(
                padding: EdgeInsets.only(left: 16, bottom: 6),
                child: Text('INGREDIENTS',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey)),
              ),
              _buildGroupedSection(children: [
                _buildInfoRow('Bean', '${_recipe.beanWeightGrams}g'),
                _buildInfoRow('Water', '${_recipe.totalWaterAmount}ml'),
                if (_recipe.grinder != null && _recipe.grinder!.isNotEmpty)
                  _buildInfoRow('Grinder', _recipe.grinder!),
                _buildInfoRow('Grind', _recipe.grindSize),
                if (_recipe.dripper != null && _recipe.dripper!.isNotEmpty)
                  _buildInfoRow('Dripper', _recipe.dripper!),
                if (_recipe.filter != null && _recipe.filter!.isNotEmpty)
                  _buildInfoRow('Filter', _recipe.filter!),
                _buildInfoRow('Total Time', _calculateTotalTime(),
                    isLast: (_recipe.note?.isEmpty ?? true)),
                if (_recipe.note != null && _recipe.note!.isNotEmpty)
                  _buildInfoRow('Note', _recipe.note!, isLast: true),
              ]),
              const SizedBox(height: 24),

              // Section 2: Steps
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 6),
                child: Text('STEPS (${_recipe.steps.length})',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey)),
              ),
              _buildGroupedSection(
                children: List.generate(_recipe.steps.length, (index) {
                  final step = _recipe.steps[index];
                  final isLast = index == _recipe.steps.length - 1;
                  return Column(
                    children: [
                      ListTile(
                        minLeadingWidth: 24,
                        leading: Text('${index + 1}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey)),
                        title: Text('${step.waterAmount}ml'),
                        trailing: Text('${step.waitTime.inSeconds}sec',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey)),
                      ),
                      if (!isLast)
                        const Divider(height: 1, indent: 16, thickness: 0.5),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 40),

              // Start Action
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PreBrewAdjustmentScreen(recipe: _recipe),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Start Brewing',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
