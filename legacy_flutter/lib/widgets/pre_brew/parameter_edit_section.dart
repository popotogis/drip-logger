import 'package:flutter/material.dart';
import '../../models/recipe.dart';

class ParameterEditSection extends StatelessWidget {
  final Recipe recipe;
  final Function(String) onGrindSizeChanged;
  final Function(double?) onTemperatureChanged;
  final Function(String) onGrinderChanged;
  final Function(String) onDripperChanged;
  final Function(String) onFilterChanged;

  const ParameterEditSection({
    super.key,
    required this.recipe,
    required this.onGrindSizeChanged,
    required this.onTemperatureChanged,
    required this.onGrinderChanged,
    required this.onDripperChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PARAMETERS',
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
              child: _buildSimpleEditField(
                label: 'Grind Size',
                initialValue: recipe.grindSize,
                onChanged: onGrindSizeChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSimpleEditField(
                label: 'Temp (°C)',
                initialValue: recipe.temperature?.toString() ?? '',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) {
                  final d = double.tryParse(val);
                  onTemperatureChanged(d);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSimpleEditField(
          label: 'Grinder',
          initialValue: recipe.grinder ?? '',
          onChanged: onGrinderChanged,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSimpleEditField(
                label: 'Dripper',
                initialValue: recipe.dripper ?? '',
                onChanged: onDripperChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSimpleEditField(
                label: 'Filter',
                initialValue: recipe.filter ?? '',
                onChanged: onFilterChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSimpleEditField({
    required String label,
    required String initialValue,
    required Function(String) onChanged,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}
