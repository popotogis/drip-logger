import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/brew_step.dart';

class StepEditList extends StatelessWidget {
  final List<BrewStep> steps;
  final Function(int index, double value) onWaterChanged;
  final Function(int index, int value) onWaitTimeChanged;
  final Function(int index, BrewStepType value) onTypeChanged;
  final Function(int index, String value) onDescriptionChanged;
  final VoidCallback?
      onAddStep; // Optional to support read-only viewing if needed
  final Function(int index)? onRemoveStep;
  final Function(int oldIndex, int newIndex)? onReorder;

  const StepEditList({
    super.key,
    required this.steps,
    required this.onWaterChanged,
    required this.onWaitTimeChanged,
    required this.onTypeChanged,
    required this.onDescriptionChanged,
    this.onAddStep,
    this.onRemoveStep,
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onReorder != null)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: onReorder!,
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              return _StepInputRow(
                // Use ValueKey(step.uid) to maintain state during edits and reordering
                key: ValueKey(step.uid),
                index: index,
                step: step,
                onWaterChanged: onWaterChanged,
                onWaitTimeChanged: onWaitTimeChanged,
                onTypeChanged: onTypeChanged,
                onDescriptionChanged: onDescriptionChanged,
                onRemoveStep: onRemoveStep,
                showDragHandle: true,
              );
            },
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              return _StepInputRow(
                key: ValueKey(step.uid),
                index: index,
                step: step,
                onWaterChanged: onWaterChanged,
                onWaitTimeChanged: onWaitTimeChanged,
                onTypeChanged: onTypeChanged,
                onDescriptionChanged: onDescriptionChanged,
                onRemoveStep: onRemoveStep,
                showDragHandle: false,
              );
            },
          ),
        if (onAddStep != null) ...[
          const SizedBox(height: 16),
          // Add Step Button
          OutlinedButton.icon(
            onPressed: onAddStep,
            icon: const Icon(Icons.add),
            label: const Text('Add Step'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ],
    );
  }
}

class _StepInputRow extends StatefulWidget {
  final int index;
  final BrewStep step;
  final Function(int index, double value) onWaterChanged;
  final Function(int index, int value) onWaitTimeChanged;
  final Function(int index, BrewStepType value) onTypeChanged;
  final Function(int index, String value) onDescriptionChanged;
  final Function(int index)? onRemoveStep;
  final bool showDragHandle;

  const _StepInputRow({
    super.key,
    required this.index,
    required this.step,
    required this.onWaterChanged,
    required this.onWaitTimeChanged,
    required this.onTypeChanged,
    required this.onDescriptionChanged,
    this.onRemoveStep,
    required this.showDragHandle,
  });

  @override
  State<_StepInputRow> createState() => _StepInputRowState();
}

class _StepInputRowState extends State<_StepInputRow> {
  late TextEditingController _waterController;
  late TextEditingController _timeController;
  late TextEditingController _descController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _waterController = TextEditingController(
      text: widget.step.waterAmount.toStringAsFixed(1),
    );
    _timeController = TextEditingController(
      text: widget.step.waitTime.inSeconds.toString(),
    );
    _descController = TextEditingController(
      text: widget.step.description ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _StepInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update Water Amount
    if (oldWidget.step.waterAmount != widget.step.waterAmount) {
      final currentVal = double.tryParse(_waterController.text);
      if (currentVal != widget.step.waterAmount) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final currentValNow = double.tryParse(_waterController.text);
            if (currentValNow != widget.step.waterAmount) {
              _waterController.text =
                  widget.step.waterAmount.toStringAsFixed(1);
            }
          }
        });
      }
    }

    // Update Wait Time
    if (oldWidget.step.waitTime != widget.step.waitTime) {
      final currentVal = int.tryParse(_timeController.text);
      if (currentVal != widget.step.waitTime.inSeconds) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final currentValNow = int.tryParse(_timeController.text);
            if (currentValNow != widget.step.waitTime.inSeconds) {
              _timeController.text = widget.step.waitTime.inSeconds.toString();
            }
          }
        });
      }
    }

    // Update Description
    if (oldWidget.step.description != widget.step.description) {
      if (_descController.text != (widget.step.description ?? '')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _descController.text = widget.step.description ?? '';
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _waterController.dispose();
    _timeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPour = widget.step.type == BrewStepType.pour;

    Color cardColor;
    switch (widget.step.type) {
      case BrewStepType.pour:
        cardColor = Colors.blue.withAlpha(26);
        break;
      case BrewStepType.wait:
        cardColor = Colors.grey.withAlpha(26);
        break;
      case BrewStepType.stir:
        cardColor = Colors.green.withAlpha(26);
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          children: [
            Row(
              children: [
                if (widget.showDragHandle) ...[
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: const Icon(Icons.drag_handle, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                ],

                // Index
                CircleAvatar(
                  radius: 12,
                  child: Text('${widget.index + 1}',
                      style: const TextStyle(fontSize: 10)),
                ),
                const SizedBox(width: 8),

                // Type Selector (Compact)
                SizedBox(
                  width: 80,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<BrewStepType>(
                        value: widget.step.type,
                        isDense: true,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87),
                        items: BrewStepType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            widget.onTypeChanged(widget.index, val);
                          }
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Water Amount (Only for Pour)
                if (isPour) ...[
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _waterController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'ml',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        final water = double.tryParse(val) ?? 0;
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce =
                            Timer(const Duration(milliseconds: 300), () {
                          widget.onWaterChanged(widget.index, water);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else
                  const Spacer(flex: 2),

                // Wait Time
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _timeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'sec',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final seconds = int.tryParse(val) ?? 0;
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 300), () {
                        widget.onWaitTimeChanged(widget.index, seconds);
                      });
                    },
                  ),
                ),

                // Remove Button
                if (widget.onRemoveStep != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => widget.onRemoveStep!(widget.index),
                  ),
              ],
            ),

            // Description (Compact)
            const SizedBox(height: 4),
            TextFormField(
              controller: _descController,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Note...',
                prefixIcon: Icon(Icons.notes, size: 14),
                prefixIconConstraints:
                    BoxConstraints(minWidth: 20, maxHeight: 20),
                contentPadding: EdgeInsets.symmetric(vertical: 4),
                border: InputBorder.none,
              ),
              onChanged: (val) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  widget.onDescriptionChanged(widget.index, val);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
