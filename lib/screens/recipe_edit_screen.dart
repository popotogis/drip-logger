import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/brew_step.dart';

/// レシピ編集・新規作成画面
///
/// レシピの基本情報（名前、粉量など）と、抽出ステップ（リスト）の編集を行います。
/// ステップの増減や時間・湯量の調整が可能です。
class RecipeEditScreen extends StatefulWidget {
  final Recipe? recipe; // 編集用のレシピ (nullなら新規作成)

  const RecipeEditScreen({super.key, this.recipe});

  @override
  State<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends State<RecipeEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // 基本パラメータ
  late String _name;
  late double _beanWeightGrams;
  late String _grinder;
  late String _grindSize;
  late String _dripper;
  late String _filter;
  late double _totalWaterAmount;
  late String _note;

  // 抽出ステップのリスト
  late List<BrewStep> _steps;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    if (r != null) {
      _name = r.name;
      _beanWeightGrams = r.beanWeightGrams;
      _grinder = r.grinder ?? '';
      _grindSize = r.grindSize;
      _dripper = r.dripper ?? '';
      _filter = r.filter ?? '';
      _totalWaterAmount = r.totalWaterAmount;
      _note = r.note ?? '';
      // リストはコピーを作成して、編集中の変更が元データに即座に影響しないようにする
      _steps = List.from(r.steps);
    } else {
      _name = '';
      _beanWeightGrams = 0;
      _grinder = '';
      _grindSize = '';
      _dripper = '';
      _filter = '';
      _totalWaterAmount = 0;
      _note = '';
      _steps = [];
    }
  }

  void _onSavePressed() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // If new recipe, just save
    if (widget.recipe == null) {
      _performSave(overwrite: false);
      return;
    }

    // If editing, ask user
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Recipe'),
        content: const Text(
            'Do you want to overwrite the existing recipe or save as a new one?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _performSave(overwrite: true);
            },
            child: const Text('Overwrite'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _performSave(overwrite: false);
            },
            child: const Text('Save as New'),
          ),
        ],
      ),
    );
  }

  void _performSave({required bool overwrite}) {
    String id;
    String name = _name;

    if (overwrite && widget.recipe != null) {
      // Overwrite: Keep original ID
      id = widget.recipe!.id;
    } else {
      // New: Generate new ID
      id = DateTime.now().toString();

      // If name conflicts with original (and we are saving as new), append date
      if (widget.recipe != null && name == widget.recipe!.name) {
        final now = DateTime.now();
        final dateSuffix =
            '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
        name = '${name}_$dateSuffix';
      }
    }

    final newRecipe = Recipe(
      id: id,
      name: name,
      beanWeightGrams: _beanWeightGrams,
      grinder: _grinder.isEmpty ? null : _grinder,
      grindSize: _grindSize,
      dripper: _dripper.isEmpty ? null : _dripper,
      filter: _filter.isEmpty ? null : _filter,
      totalWaterAmount: _totalWaterAmount,
      note: _note,
      steps: _steps,
    );

    Navigator.pop(context, newRecipe);
  }

  // ステップ数が変更されたときにリストを調整する
  void _updateStepCount(String value) {
    // 入力が空の場合は0として扱う
    if (value.isEmpty) {
      if (_steps.isNotEmpty) {
        setState(() {
          _steps.clear();
        });
      }
      return;
    }

    final count = int.tryParse(value);
    if (count == null) return; // 数値でない場合は無視

    setState(() {
      if (count > _steps.length) {
        // 増えた分を追加 (初期値0でおく)
        final diff = count - _steps.length;
        for (var i = 0; i < diff; i++) {
          _steps.add(
              BrewStep(waterAmount: 0, waitTime: const Duration(seconds: 0)));
        }
      } else if (count < _steps.length) {
        // 減った分を末尾から削除
        _steps.removeRange(count, _steps.length);
      }
    });
  }

  // 特定のステップの値を更新する
  void _updateStep(int index, {double? water, int? time}) {
    if (index < 0 || index >= _steps.length) return;

    final oldStep = _steps[index];
    // setState不要 (FormのonSaved/onChangedでデータモデルだけ更新すれば、次回buildで反映される。
    // ただし、即座に値を確定させるためにデータは更新しておく)
    _steps[index] = BrewStep(
      waterAmount: water ?? oldStep.waterAmount,
      waitTime: time != null ? Duration(seconds: time) : oldStep.waitTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null ? 'New Recipe' : 'Edit Recipe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // --- 基本情報入力 ---
                TextFormField(
                  initialValue: _name,
                  decoration: const InputDecoration(labelText: 'Recipe Name'),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Required' : null,
                  onSaved: (value) => _name = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue:
                      _beanWeightGrams > 0 ? _beanWeightGrams.toString() : '',
                  decoration:
                      const InputDecoration(labelText: 'Bean Weight (g)'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Required' : null,
                  onSaved: (value) =>
                      _beanWeightGrams = double.tryParse(value ?? '') ?? 0,
                ),
                TextFormField(
                  initialValue: _grinder,
                  decoration:
                      const InputDecoration(labelText: 'Grinder (e.g. C40)'),
                  onSaved: (value) => _grinder = value ?? '',
                ),
                TextFormField(
                  initialValue: _grindSize,
                  decoration: const InputDecoration(labelText: 'Grind Size'),
                  onSaved: (value) => _grindSize = value ?? '',
                ),
                TextFormField(
                  initialValue: _dripper,
                  decoration:
                      const InputDecoration(labelText: 'Dripper (e.g. V60)'),
                  onSaved: (value) => _dripper = value ?? '',
                ),
                TextFormField(
                  initialValue: _filter,
                  decoration: const InputDecoration(labelText: 'Filter'),
                  onSaved: (value) => _filter = value ?? '',
                ),
                TextFormField(
                  initialValue:
                      _totalWaterAmount > 0 ? _totalWaterAmount.toString() : '',
                  decoration:
                      const InputDecoration(labelText: 'Total Water (ml)'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Required' : null,
                  onSaved: (value) =>
                      _totalWaterAmount = double.tryParse(value ?? '') ?? 0,
                ),
                TextFormField(
                  initialValue: _note,
                  decoration: const InputDecoration(labelText: 'Note'),
                  maxLines: 3,
                  onSaved: (value) => _note = value ?? '',
                ),
                const SizedBox(height: 24),

                // --- ステップ数入力 ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Brewing Steps',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextFormField(
                        initialValue:
                            _steps.isNotEmpty ? _steps.length.toString() : '',
                        decoration: const InputDecoration(
                          labelText: 'Count',
                          helperText: 'Enter number of steps',
                        ),
                        keyboardType: TextInputType.number,
                        // ステップ数を入力すると、リストのサイズが変わる
                        onChanged: _updateStepCount,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- ステップ入力リスト ---
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0, // HIG style
                      color: Colors.grey[200], // HIG style background
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text(
                              'Step ${index + 1}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 16),
                            // 湯量入力
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Water',
                                  suffixText: 'ml',
                                  isDense: true,
                                  border: InputBorder.none, // Cleaner look
                                ),
                                keyboardType: TextInputType.number,
                                // 初期値をセット（簡易実装）
                                initialValue: step.waterAmount > 0
                                    ? step.waterAmount.toString()
                                    : '',
                                onChanged: (val) => _updateStep(index,
                                    water: double.tryParse(val)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // 時間入力
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Time',
                                  suffixText: 'sec',
                                  isDense: true,
                                  border: InputBorder.none,
                                ),
                                keyboardType: TextInputType.number,
                                initialValue: step.waitTime.inSeconds > 0
                                    ? step.waitTime.inSeconds.toString()
                                    : '',
                                onChanged: (val) =>
                                    _updateStep(index, time: int.tryParse(val)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 保存ボタン
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _onSavePressed,
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(height: 48), // 下部に余白
              ],
            ),
          ),
        ),
      ),
    );
  }
}
