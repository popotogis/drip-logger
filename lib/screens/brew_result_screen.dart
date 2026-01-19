import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import '../models/brew_result.dart';
import '../models/bean.dart';
import '../repositories/bean_repository.dart';

class BrewResultScreen extends StatefulWidget {
  final BrewResult result;

  const BrewResultScreen({super.key, required this.result});

  @override
  State<BrewResultScreen> createState() => _BrewResultScreenState();
}

class _BrewResultScreenState extends State<BrewResultScreen> {
  final BeanRepository _beanRepository = BeanRepository();
  List<Bean> _beans = [];

  late TextEditingController _noteController;
  Bean? _selectedBean;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.result.notes);
    _selectedBean = widget.result.bean;
    _loadBeans();
  }

  Future<void> _loadBeans() async {
    final beans = await _beanRepository.loadBeans();
    if (mounted) {
      setState(() {
        _beans = beans;
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showAddBeanDialog() {
    final nameController = TextEditingController();
    final roasterController = TextEditingController();
    final originController = TextEditingController();
    final roastLevelController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Bean'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'Bean Name (Required)')),
              TextField(
                  controller: roasterController,
                  decoration: const InputDecoration(labelText: 'Roaster')),
              TextField(
                  controller: originController,
                  decoration: const InputDecoration(labelText: 'Origin')),
              TextField(
                  controller: roastLevelController,
                  decoration: const InputDecoration(labelText: 'Roast Level')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              final newBean = Bean(
                id: DateTime.now().toString(),
                name: nameController.text,
                roaster: roasterController.text,
                origin: originController.text,
                roastLevel: roastLevelController.text,
              );
              setState(() {
                _beans.add(newBean);
                _selectedBean = newBean;
              });
              _beanRepository.saveBeans(_beans);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Bean>(
                    decoration: const InputDecoration(
                      labelText: 'Select Bean',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedBean,
                    items: _beans.map((bean) {
                      return DropdownMenuItem(
                        value: bean,
                        child: Text('${bean.name} (${bean.roaster})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedBean = val;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddBeanDialog,
                  tooltip: 'Add New Bean',
                ),
              ],
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

            // Actions
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Create updated result
                  final updatedResult = widget.result.copyWith(
                    bean: _selectedBean,
                    notes: _noteController.text,
                  );

                  final md = updatedResult.toMarkdown();
                  Clipboard.setData(ClipboardData(text: md));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to Clipboard!')),
                  );
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
                  final updatedResult = widget.result.copyWith(
                    bean: _selectedBean,
                    notes: _noteController.text,
                  );
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

                  if (mounted) {
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
                onPressed: () {
                  // Navigate back to list (pop until first)
                  Navigator.popUntil(context, (route) => route.isFirst);
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
    return "$minutes:$seconds";
  }
}
