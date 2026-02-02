import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/bean.dart';
import '../repositories/bean_repository.dart';

/// 豆リスト管理画面
///
/// 保存されているコーヒー豆のリスト表示、追加、編集、削除を行います。
/// [isSelectionMode] が true の場合は、抽出結果に紐づける豆を選択するモードとして動作します。
class BeanListScreen extends StatefulWidget {
  final bool isSelectionMode;

  const BeanListScreen({
    super.key,
    this.isSelectionMode = false,
  });

  @override
  State<BeanListScreen> createState() => _BeanListScreenState();
}

class _BeanListScreenState extends State<BeanListScreen> {
  final BeanRepository _repository = BeanRepository();
  List<Bean> _beans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBeans();
  }

  Future<void> _loadBeans() async {
    final beans = await _repository.loadBeans();
    if (mounted) {
      setState(() {
        _beans = beans;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBeans() async {
    await _repository.saveBeans(_beans);
  }

  void _showBeanInputCallback({Bean? bean}) {
    final nameController = TextEditingController(text: bean?.name);
    final roasterController = TextEditingController(text: bean?.roaster);
    final originController = TextEditingController(text: bean?.origin);
    final roastLevelController = TextEditingController(text: bean?.roastLevel);
    final processController = TextEditingController(text: bean?.process);
    final varietyController = TextEditingController(text: bean?.variety);

    DateTime? selectedDate = bean?.roastDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bean == null ? 'Add New Bean' : 'Edit Bean'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Bean Name *'),
                autofocus: true,
              ),
              TextField(
                controller: roasterController,
                decoration: const InputDecoration(labelText: 'Roaster'),
              ),
              TextField(
                controller: originController,
                decoration: const InputDecoration(labelText: 'Origin'),
              ),
              TextField(
                controller: roastLevelController,
                decoration: const InputDecoration(labelText: 'Roast Level'),
              ),
              TextField(
                controller: processController,
                decoration:
                    const InputDecoration(labelText: 'Process (e.g. washed)'),
              ),
              TextField(
                controller: varietyController,
                decoration:
                    const InputDecoration(labelText: 'Variety (e.g. Geisha)'),
              ),
              const SizedBox(height: 16),

              // Date Picker
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Text(
                      selectedDate == null
                          ? 'Selected Roast Date'
                          : 'Roast Date: ${selectedDate!.toString().split(' ')[0]}',
                    ),
                  ),
                  if (selectedDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          selectedDate = null;
                        });
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              final newBean = Bean(
                id: bean?.id ?? DateTime.now().toString(),
                name: nameController.text,
                roaster: roasterController.text,
                origin: originController.text,
                roastLevel: roastLevelController.text,
                process: processController.text.isEmpty
                    ? null
                    : processController.text,
                variety: varietyController.text.isEmpty
                    ? null
                    : varietyController.text,
                roastDate: selectedDate,
                lastUsed: bean?.lastUsed,
              );

              if (bean == null) {
                // Add
                _beans.add(newBean);
              } else {
                // Edit
                final index = _beans.indexWhere((b) => b.id == bean.id);
                if (index != -1) {
                  _beans[index] = newBean;
                }
              }

              await _saveBeans();
              // Reload to ensure sort (though for add/edit we might not need re-sort immediately, but let's be consistent)
              await _loadBeans();

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? 'Select Bean' : 'Beans'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBeanInputCallback(),
        child: const Icon(Icons.add),
      ),
      body: _beans.isEmpty
          ? Center(
              child: Text(
                'No beans yet.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          : ListView.separated(
              itemCount: _beans.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 16),
              itemBuilder: (context, index) {
                final bean = _beans[index];
                return Slidable(
                  key: Key(bean.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    extentRatio: 0.25,
                    children: [
                      SlidableAction(
                        onPressed: (context) async {
                          final deletedName = bean.name;
                          setState(() {
                            _beans.removeAt(index);
                          });
                          await _saveBeans();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$deletedName deleted')),
                            );
                          }
                        },
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(
                      bean.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      [
                        if (bean.roaster.isNotEmpty) bean.roaster,
                        if (bean.origin.isNotEmpty) bean.origin,
                        if (bean.roastLevel.isNotEmpty) bean.roastLevel
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () async {
                      if (widget.isSelectionMode) {
                        // Update last used
                        await _repository.updateLastUsed(bean.id);
                        if (context.mounted) {
                          Navigator.pop(context, bean);
                        }
                      } else {
                        // Edit
                        _showBeanInputCallback(bean: bean);
                      }
                    },
                    trailing: widget.isSelectionMode
                        ? null
                        : const Icon(Icons.edit, size: 20, color: Colors.grey),
                  ),
                );
              },
            ),
    );
  }
}
