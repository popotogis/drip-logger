import 'package:flutter/material.dart';

class BeanWeightSection extends StatelessWidget {
  final double beanWeight;
  final bool maintainRatio;
  final Function(double) onWeightChanged;
  final Function(bool) onMaintainRatioChanged;

  const BeanWeightSection({
    super.key,
    required this.beanWeight,
    required this.maintainRatio,
    required this.onWeightChanged,
    required this.onMaintainRatioChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BEAN WEIGHT',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                // Use key to update when value changes externally (e.g. from original edit)
                key: ValueKey('bean_weight_$beanWeight'),
                initialValue: beanWeight.toString(),
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
                  if (weight > 0) onWeightChanged(weight);
                },
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                const Text('Scale Steps', style: TextStyle(fontSize: 12)),
                Switch(
                  value: maintainRatio,
                  onChanged: onMaintainRatioChanged,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
