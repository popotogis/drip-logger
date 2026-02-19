import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brew_result.dart';
import '../models/bean.dart';
import '../repositories/brew_result_repository.dart';
import '../repositories/recipe_repository.dart';
import 'bean_list_screen.dart';

/// 抽出結果画面
///
/// ドリップ完了後の実績データを表示します。
/// 感想（Tasting Notes）の入力や、Markdown形式でのファイル保存/コピーが可能です。
/// 画面を離れる際やアクション実行時に、DB上のデータを更新します。
class BrewResultScreen extends ConsumerStatefulWidget {
  final BrewResult result;

  const BrewResultScreen({super.key, required this.result});

  @override
  ConsumerState<BrewResultScreen> createState() => _BrewResultScreenState();
}

class _BrewResultScreenState extends ConsumerState<BrewResultScreen> {
  late TextEditingController _noteController;
  Bean? _selectedBean;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.result.notes);
    _selectedBean = widget.result.bean;
    _checkModification();
  }

  Future<void> _checkModification() async {
    final original = await ref
        .read(recipeRepositoryProvider)
        .getRecipe(widget.result.recipe.id);
    if (original != null) {
      if (mounted) {
        setState(() {
          _isModified = widget.result.recipe.isContentDifferent(original);
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isModified = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// 現在の入力状態を反映したBrewResultを作成し、DBを更新します
  Future<BrewResult> _updateAndSave() async {
    final updatedResult = widget.result.copyWith(
      bean: _selectedBean,
      notes: _noteController.text,
    );
    await ref.read(brewResultRepositoryProvider).addResult(updatedResult);
    return updatedResult;
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brew Result'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(result.recipe.name,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('Total Time: ${_formatDuration(result.totalTime)}',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(
                        'Date: ${result.brewedAt.toString().substring(0, 16)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bean Selection
            const Text('Bean Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            InkWell(
              onTap: () async {
                final selected = await Navigator.push<Bean>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const BeanListScreen(isSelectionMode: true),
                  ),
                );
                if (selected != null) {
                  setState(() {
                    _selectedBean = selected;
                  });
                  // Auto-save on selection? Or just wait for explicit action/exit.
                  // Let's optimize by not saving on every selection but relying on exit/actions.
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Select Bean',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _selectedBean == null
                          ? const Text('Choose a bean...',
                              style: TextStyle(color: Colors.grey))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _selectedBean!.name,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                if (_selectedBean!.roaster.isNotEmpty)
                                  Text(
                                    _selectedBean!.roaster,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                              ],
                            ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),

            if (_selectedBean != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                    'Roast: ${_selectedBean!.roastLevel} / Origin: ${_selectedBean!.origin}',
                    style: const TextStyle(color: Colors.grey)),
              ),

            const SizedBox(height: 24),

            // Steps Table
            const Text('Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FixedColumnWidth(40),
                1: FlexColumnWidth(),
                2: FixedColumnWidth(80),
                3: FixedColumnWidth(80),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Colors.black12),
                  children: [
                    Padding(padding: EdgeInsets.all(8.0), child: Text('#')),
                    Padding(padding: EdgeInsets.all(8.0), child: Text('Water')),
                    Padding(padding: EdgeInsets.all(8.0), child: Text('Plan')),
                    Padding(
                        padding: EdgeInsets.all(8.0), child: Text('Actual')),
                  ],
                ),
                ...result.steps.map((step) => TableRow(
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('${step.stepIndex + 1}')),
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('${step.waterAmount}ml')),
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('${step.plannedTime.inSeconds}s')),
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(_formatDuration(step.actualTime))),
                      ],
                    )),
              ],
            ),
            const SizedBox(height: 24),

            // Notes
            const Text('Tasting Notes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Taste, Aroma, Body, etc...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            // --- 新規レシピとして保存の提案 ---
            if (_isModified)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final nameController = TextEditingController(
                        text: '${result.recipe.name} (Adjusted)');
                    final newName = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Save as New Recipe'),
                        content: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Recipe Name',
                            hintText: 'Enter new recipe name',
                          ),
                          autofocus: true,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, nameController.text),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    );

                    if (newName != null && newName.isNotEmpty) {
                      final newRecipe = result.recipe.copyWith(
                        id: DateTime.now().toString(),
                        name: newName,
                        lastUsed: DateTime.now(),
                      );
                      await ref
                          .read(recipeRepositoryProvider)
                          .saveRecipe(newRecipe);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved as new recipe!')),
                        );
                        setState(() {
                          _isModified = false;
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Save as New Recipe'),
                ),
              ),
            if (_isModified) const SizedBox(height: 16),

            // Actions
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final updatedResult = await _updateAndSave();

                  final md = updatedResult.toMarkdown();
                  Clipboard.setData(ClipboardData(text: md));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to Clipboard!')),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy as Markdown'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final updatedResult = await _updateAndSave();
                  final md = updatedResult.toMarkdown();

                  // Filename: yyyyMMdd_HHmm_BeanName
                  final date = updatedResult.brewedAt;
                  final yyyy = date.year.toString();
                  final mm = date.month.toString().padLeft(2, '0');
                  final dd = date.day.toString().padLeft(2, '0');
                  final hh = date.hour.toString().padLeft(2, '0');
                  final min = date.minute.toString().padLeft(2, '0');
                  final beanName = _selectedBean?.name
                          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_') ??
                      'NoBean';

                  final filename = '$yyyy$mm${dd}_$hh${min}_$beanName';

                  await FileSaver.instance.saveFile(
                    name: '$filename.md',
                    bytes: utf8.encode(md),
                    mimeType: MimeType.text,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File Saved!')),
                    );
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('Save as File'),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: TextButton(
                onPressed: () async {
                  await _updateAndSave();
                  if (context.mounted) {
                    // Navigate back to list (pop until first)
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                },
                child: const Text('Back to Home'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
