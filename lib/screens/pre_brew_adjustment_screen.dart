import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/brew_step.dart';
import 'brewing_screen.dart';

/// 抽出前調整画面
///
/// レシピを元に、その時の状況（豆の量や味の好み）に合わせて一時的にパラメータを変更します。
class PreBrewAdjustmentScreen extends StatefulWidget {
  final Recipe recipe;

  const PreBrewAdjustmentScreen({super.key, required this.recipe});

  @override
  State<PreBrewAdjustmentScreen> createState() =>
      _PreBrewAdjustmentScreenState();
}

class _PreBrewAdjustmentScreenState extends State<PreBrewAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late Recipe _tempRecipe;
  bool _maintainRatio = true;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final ratio = _tempRecipe.beanWeightGrams > 0
        ? _tempRecipe.totalWaterAmount / _tempRecipe.beanWeightGrams
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjust Recipe'),
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
                      trailing: Text('${step.waitTime.inSeconds}s',
                          style: const TextStyle(color: Colors.grey)),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Start Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pushReplacement(
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
}
