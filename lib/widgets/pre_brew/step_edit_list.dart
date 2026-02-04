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
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              radius: 14,
              child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
            ),
            title: Row(
              children: [
                const Text('Water: '),
                Expanded(
                  child: TextFormField(
                    // Key is crucial for updating when steps change significantly
                    key: ValueKey('step_${index}_${step.waterAmount}'),
                    initialValue: step.waterAmount.toStringAsFixed(1),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      isDense: true,
                      suffixText: 'ml',
                    ),
                    onChanged: (val) {
                      final water = double.tryParse(val) ?? 0;
                      onWaterChanged(index, water);
                    },
                  ),
                ),
              ],
            ),
            trailing: SizedBox(
              width: 60,
              child: TextFormField(
                key: ValueKey('step_time_${index}_${step.waitTime.inSeconds}'),
                initialValue: step.waitTime.inSeconds.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  suffixText: 's',
                ),
                onChanged: (val) {
                  final seconds = int.tryParse(val) ?? 0;
                  onWaitTimeChanged(index, seconds);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
