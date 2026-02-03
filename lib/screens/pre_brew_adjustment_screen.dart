import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/brew_step.dart';
import '../utils/recipe_sharer.dart';
import 'brewing_screen.dart';
import 'recipe_edit_screen.dart';
import '../repositories/recipe_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

/// 抽出前調整画面
///
/// レシピを元に、その時の状況（豆の量や味の好み）に合わせて一時的にパラメータを変更します。
class PreBrewAdjustmentScreen extends ConsumerStatefulWidget {
  final Recipe recipe;

  const PreBrewAdjustmentScreen({super.key, required this.recipe});

  @override
  ConsumerState<PreBrewAdjustmentScreen> createState() =>
      _PreBrewAdjustmentScreenState();
}

class _PreBrewAdjustmentScreenState
    extends ConsumerState<PreBrewAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late Recipe _baseRecipe; // 編集・共有用の大元のレシピ
  late Recipe _tempRecipe; // 調整用のレシピ
  bool _maintainRatio = true;

  @override
  void initState() {
    super.initState();
    _baseRecipe = widget.recipe;
    // 編集用にコピーを作成
    _tempRecipe = widget.recipe;
  }

  void _updateBeanWeight(double newWeight) {
    setState(() {
      if (_maintainRatio) {
        _tempRecipe = _tempRecipe.scaleToBeanWeight(newWeight);
      } else {
        _tempRecipe = _tempRecipe.copyWith(beanWeightGrams: newWeight);
      }
    });
  }

  void _updateStepWater(int index, double newWater) {
    final newSteps = List<BrewStep>.from(_tempRecipe.steps);
    newSteps[index] = BrewStep(
      waterAmount: newWater,
      waitTime: newSteps[index].waitTime,
    );

    setState(() {
      // 総湯量も更新
      final newTotal = newSteps.fold(0.0, (sum, s) => sum + s.waterAmount);
      _tempRecipe = _tempRecipe.copyWith(
        steps: newSteps,
        totalWaterAmount: newTotal,
      );
    });
  }

  void _updateStepWaitTime(int index, int newSeconds) {
    final newSteps = List<BrewStep>.from(_tempRecipe.steps);
    newSteps[index] = BrewStep(
      waterAmount: newSteps[index].waterAmount,
      waitTime: Duration(seconds: newSeconds),
    );

    setState(() {
      _tempRecipe = _tempRecipe.copyWith(steps: newSteps);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _tempRecipe.beanWeightGrams > 0
        ? _tempRecipe.totalWaterAmount / _tempRecipe.beanWeightGrams
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjust Recipe'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  await _editOriginal();
                  break;
                case 'share':
                  await _shareRecipe();
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
              Card(
                elevation: 4,
                shadowColor:
                    Theme.of(context).colorScheme.shadow.withOpacity(0.2),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                          'Ratio', '1:${ratio.toStringAsFixed(1)}'),
                      _buildSummaryItem('Total Water',
                          '${_tempRecipe.totalWaterAmount.toStringAsFixed(1)}ml'),
                      _buildSummaryItem('Bean',
                          '${_tempRecipe.beanWeightGrams.toStringAsFixed(1)}g'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bean Weight Section
              const Text('BEAN WEIGHT',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _tempRecipe.beanWeightGrams.toString(),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        suffixText: 'g',
                        border: OutlineInputBorder(),
                        errorMaxLines: 2,
                      ),
                      validator: (val) {
                        final d = double.tryParse(val ?? '');
                        if (d == null || d <= 0) return 'Invalid';
                        if (d > 1000) return 'Too large';
                        return null;
                      },
                      onChanged: (val) {
                        final weight = double.tryParse(val) ?? 0;
                        if (weight > 0) _updateBeanWeight(weight);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      const Text('Scale Steps', style: TextStyle(fontSize: 12)),
                      Switch(
                        value: _maintainRatio,
                        onChanged: (val) =>
                            setState(() => _maintainRatio = val),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Other Params
              const Text('PARAMETERS',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildSimpleEditField(
                      label: 'Grind Size',
                      initialValue: _tempRecipe.grindSize,
                      validator: (val) =>
                          (val == null || val.isEmpty) ? 'Required' : null,
                      onChanged: (val) =>
                          _tempRecipe = _tempRecipe.copyWith(grindSize: val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSimpleEditField(
                      label: 'Temp (°C)',
                      initialValue: _tempRecipe.temperature?.toString() ?? '',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.isEmpty) return null;
                        final d = double.tryParse(val);
                        if (d == null || d < 0 || d > 100) return 'Invalid';
                        return null;
                      },
                      onChanged: (val) => _tempRecipe = _tempRecipe.copyWith(
                          temperature: double.tryParse(val)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSimpleEditField(
                label: 'Grinder',
                initialValue: _tempRecipe.grinder ?? '',
                onChanged: (val) =>
                    _tempRecipe = _tempRecipe.copyWith(grinder: val),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSimpleEditField(
                      label: 'Dripper',
                      initialValue: _tempRecipe.dripper ?? '',
                      onChanged: (val) =>
                          _tempRecipe = _tempRecipe.copyWith(dripper: val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSimpleEditField(
                      label: 'Filter',
                      initialValue: _tempRecipe.filter ?? '',
                      onChanged: (val) =>
                          _tempRecipe = _tempRecipe.copyWith(filter: val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Steps Section
              const Text('STEPS (Adjust Water for Taste)',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tempRecipe.steps.length,
                itemBuilder: (context, index) {
                  final step = _tempRecipe.steps[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 14,
                        child: Text('${index + 1}',
                            style: const TextStyle(fontSize: 12)),
                      ),
                      title: Row(
                        children: [
                          const Text('Water: '),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey(
                                  'step_${index}_${step.waterAmount}'), // Ensure it recreates when scaled
                              initialValue: step.waterAmount.toStringAsFixed(1),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                isDense: true,
                                suffixText: 'ml',
                              ),
                              validator: (val) {
                                final d = double.tryParse(val ?? '');
                                if (d == null || d < 0) return 'Invalid';
                                return null;
                              },
                              onChanged: (val) {
                                final water = double.tryParse(val) ?? 0;
                                _updateStepWater(index, water);
                              },
                            ),
                          ),
                        ],
                      ),
                      trailing: SizedBox(
                        width: 60,
                        child: TextFormField(
                          key: ValueKey(
                              'step_time_${index}_${step.waitTime.inSeconds}'),
                          initialValue: step.waitTime.inSeconds.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            suffixText: 's',
                          ),
                          onChanged: (val) {
                            final seconds = int.tryParse(val) ?? 0;
                            _updateStepWaitTime(index, seconds);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Note
              _buildSimpleEditField(
                label: 'Note',
                initialValue: _tempRecipe.note ?? '',
                onChanged: (val) =>
                    _tempRecipe = _tempRecipe.copyWith(note: val),
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
                              BrewingScreen(recipe: _tempRecipe),
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

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSimpleEditField({
    required String label,
    required String initialValue,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }

  Future<void> _editOriginal() async {
    final updatedRecipe = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeEditScreen(recipe: _baseRecipe),
      ),
    );

    if (updatedRecipe != null && updatedRecipe is Recipe) {
      // リポジトリに保存
      await ref.read(recipeRepositoryProvider).saveRecipe(updatedRecipe);

      setState(() {
        _baseRecipe = updatedRecipe;
        // 調整中の内容もリセットして元レシピに合わせる（UXとしてその方が自然）
        _tempRecipe = updatedRecipe;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Original recipe updated')),
        );
      }
    }
  }

  Future<void> _shareRecipe() async {
    // 共有するのは「元レシピ」か「調整後」か？
    // DetailScreenの代替機能としては「元レシピ」を共有すべき。
    final code = RecipeSharer.encode(_baseRecipe);
    if (code.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: code));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe copied to clipboard!')),
        );
      }
    }
  }
}
