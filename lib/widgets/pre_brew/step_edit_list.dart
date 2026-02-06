import 'package:flutter/material.dart';
import '../../models/brew_step.dart';

class StepEditList extends StatelessWidget {
  final List<BrewStep> steps;
  final Function(int index, double value) onWaterChanged;
  final Function(int index, int value) onWaitTimeChanged;

  const StepEditList({
    super.key,
    required this.steps,
    required this.onWaterChanged,
    required this.onWaitTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
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
        );
      },
    );
  }
}

class _StepInputRow extends StatefulWidget {
  final int index;
  final BrewStep step;
  final Function(int index, double value) onWaterChanged;
  final Function(int index, int value) onWaitTimeChanged;

  const _StepInputRow({
    super.key,
    required this.index,
    required this.step,
    required this.onWaterChanged,
    required this.onWaitTimeChanged,
  });

  @override
  State<_StepInputRow> createState() => _StepInputRowState();
}

class _StepInputRowState extends State<_StepInputRow> {
  late TextEditingController _waterController;
  late TextEditingController _timeController;

  @override
  void initState() {
    super.initState();
    _waterController = TextEditingController(
      text: widget.step.waterAmount.toStringAsFixed(1),
    );
    _timeController = TextEditingController(
      text: widget.step.waitTime.inSeconds.toString(),
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
  }

  @override
  void dispose() {
    _waterController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 14,
          child:
              Text('${widget.index + 1}', style: const TextStyle(fontSize: 12)),
        ),
        title: Row(
          children: [
            const Text('Water: '),
            Expanded(
              child: TextFormField(
                controller: _waterController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  isDense: true,
                  suffixText: 'ml',
                ),
                onChanged: (val) {
                  final water = double.tryParse(val) ?? 0;
                  widget.onWaterChanged(widget.index, water);
                },
              ),
            ),
          ],
        ),
        trailing: SizedBox(
          width: 60,
          child: TextFormField(
            controller: _timeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              isDense: true,
              suffixText: 's',
            ),
            onChanged: (val) {
              final seconds = int.tryParse(val) ?? 0;
              widget.onWaitTimeChanged(widget.index, seconds);
            },
          ),
        ),
      ),
    );
  }
}
