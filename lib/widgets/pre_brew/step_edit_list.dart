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

  const StepEditList({
    super.key,
    required this.steps,
    required this.onWaterChanged,
    required this.onWaitTimeChanged,
    required this.onTypeChanged,
    required this.onDescriptionChanged,
    this.onAddStep,
    this.onRemoveStep,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: steps.length,
          itemBuilder: (context, index) {
            final step = steps[index];
            return _StepInputRow(
              // Keyをindexベースにして、値が変わってもWidget自体は再利用されるようにする
              key: ValueKey('step_row_$index'),
              index: index,
              step: step,
              onWaterChanged: onWaterChanged,
              onWaitTimeChanged: onWaitTimeChanged,
              onTypeChanged: onTypeChanged,
              onDescriptionChanged: onDescriptionChanged,
              onRemoveStep: onRemoveStep,
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

  const _StepInputRow({
    super.key,
    required this.index,
    required this.step,
    required this.onWaterChanged,
    required this.onWaitTimeChanged,
    required this.onTypeChanged,
    required this.onDescriptionChanged,
    this.onRemoveStep,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      // elevation: 0, // RecipeEditScreenに合わせるならelevation 0 + grey background 等が良いが、
      // ここでは既存デザイン(Cardデフォルト)を維持しつつ機能追加に留めるか、統一するか。
      // PreBrewAdjustmentScreenは白背景なのでCardデフォルトでOK。
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text('${widget.index + 1}',
                      style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      // Top Row: Type Selector & Time
                      Row(
                        children: [
                          // Type Selector
                          SizedBox(
                            width: 100,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 8),
                                border: InputBorder.none,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<BrewStepType>(
                                  value: widget.step.type,
                                  isDense: true,
                                  items: BrewStepType.values.map((type) {
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(type.name.toUpperCase(),
                                          style: const TextStyle(fontSize: 12)),
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
                          const Spacer(),
                          // Wait Time Input
                          SizedBox(
                            width: 60,
                            child: TextFormField(
                              controller: _timeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                isDense: true,
                                suffixText: 's',
                                labelText: 'Time',
                              ),
                              onChanged: (val) {
                                final seconds = int.tryParse(val) ?? 0;
                                if (_debounce?.isActive ?? false) {
                                  _debounce!.cancel();
                                }
                                _debounce = Timer(
                                    const Duration(milliseconds: 300), () {
                                  widget.onWaitTimeChanged(
                                      widget.index, seconds);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      // Middle Row: Water Amount (Only for Pour)
                      if (isPour) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.water_drop,
                                size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _waterController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  suffixText: 'ml',
                                  labelText: 'Water Amount',
                                ),
                                onChanged: (val) {
                                  final water = double.tryParse(val) ?? 0;
                                  if (_debounce?.isActive ?? false) {
                                    _debounce!.cancel();
                                  }
                                  _debounce = Timer(
                                      const Duration(milliseconds: 300), () {
                                    widget.onWaterChanged(widget.index, water);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Bottom Row: Description
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description / Note',
                          isDense: true,
                          prefixIcon: Icon(Icons.notes, size: 16),
                        ),
                        onChanged: (val) {
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce =
                              Timer(const Duration(milliseconds: 300), () {
                            widget.onDescriptionChanged(widget.index, val);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // Remove Button
                if (widget.onRemoveStep != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () => widget.onRemoveStep!(widget.index),
                    tooltip: 'Remove Step',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
