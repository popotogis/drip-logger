import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/brew_step.dart';
import '../widgets/pre_brew/step_edit_list.dart';

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
  double? _temperature;
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
      _temperature = r.temperature;
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
      _temperature = null;
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
      temperature: _temperature,
      totalWaterAmount: _totalWaterAmount,
      note: _note,
      steps: _steps,
    );

    Navigator.pop(context, newRecipe);
  }

  // ステップを追加する
  void _addStep() {
    setState(() {
      _steps.add(
        BrewStep(
          type: BrewStepType.pour,
          waterAmount: 0,
          waitTime: const Duration(seconds: 0),
        ),
      );
    });
  }

  // ステップを削除する
  void _removeStep(int index) {
    if (index < 0 || index >= _steps.length) return;
    setState(() {
      _steps.removeAt(index);
    });
  }

  // ステップを入れ替える
  void _reorderSteps(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, item);
    });
  }

  // 特定のステップの値を更新する
  void _updateStep(int index,
      {double? water, int? time, BrewStepType? type, String? description}) {
    if (index < 0 || index >= _steps.length) return;

    final oldStep = _steps[index];

    // typeがwait/stirに変更された場合、waterを0にする
    double newWater = water ?? oldStep.waterAmount;
    final newType = type ?? oldStep.type;

    if (newType == BrewStepType.wait || newType == BrewStepType.stir) {
      if (type != null) {
        // タイプが明示的に変更された場合のみ0リセット（ユーザーが意図して入力している場合は残すべきか？ -> 仕様では0固定）
        // ここでは「タイプ変更時」および「入力時」に強制的に0にするロジックにするか、
        // UIで隠れているので自然に0になるのを待つかだが、データ整合性のために強制0にする
        newWater = 0;
      } else {
        // type変更なしでwater変更が来た場合も、wait/stirなら0に強制する？
        // いや、water入力自体非表示なので来ないはずだが、念のため
        // newWater = 0; // これを有効にすると water入力を受け付けなくなる
      }
    }

    // setStateで再描画して、Type変更時のUI切り替え（Water入力の表示/非表示）を即時反映させる
    setState(() {
      _steps[index] = BrewStep(
        type: newType,
        waterAmount: newWater,
        waitTime: time != null ? Duration(seconds: time) : oldStep.waitTime,
        description: description ?? oldStep.description,
        uid: oldStep.uid,
      );
    });
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
                  decoration: const InputDecoration(labelText: 'Recipe Name *'),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Required' : null,
                  onSaved: (value) => _name = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue:
                      _beanWeightGrams > 0 ? _beanWeightGrams.toString() : '',
                  decoration:
                      const InputDecoration(labelText: 'Bean Weight (g) *'),
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
                  initialValue:
                      _totalWaterAmount > 0 ? _totalWaterAmount.toString() : '',
                  decoration:
                      const InputDecoration(labelText: 'Total Water (ml) *'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Required' : null,
                  onSaved: (value) =>
                      _totalWaterAmount = double.tryParse(value ?? '') ?? 0,
                ),
                TextFormField(
                  initialValue: _temperature?.toString() ?? '',
                  decoration:
                      const InputDecoration(labelText: 'Temperature (°C)'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) =>
                      _temperature = double.tryParse(value ?? ''),
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
                  initialValue: _note,
                  decoration: const InputDecoration(labelText: 'Note'),
                  maxLines: 3,
                  onSaved: (value) => _note = value ?? '',
                ),
                const SizedBox(height: 24),

                // --- ステップ数入力 (削除) ---
                // Row(..., Expanded(child: TextFormField(..., onChanged: _updateStepCount))),

                const Text(
                  'Brewing Steps',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // --- ステップ入力リスト (共通コンポーネント) ---
                StepEditList(
                  steps: _steps,
                  onWaterChanged: (index, val) =>
                      _updateStep(index, water: val),
                  onWaitTimeChanged: (index, val) =>
                      _updateStep(index, time: val),
                  onTypeChanged: (index, val) => _updateStep(index, type: val),
                  onDescriptionChanged: (index, val) =>
                      _updateStep(index, description: val),
                  onAddStep: _addStep,
                  onRemoveStep: _removeStep,
                  onReorder: _reorderSteps,
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
