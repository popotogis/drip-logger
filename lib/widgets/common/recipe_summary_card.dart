import 'package:flutter/material.dart';
import '../../models/recipe.dart';

class RecipeSummaryCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeSummaryCard({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate ratio
    final ratio = recipe.beanWeightGrams > 0
        ? recipe.totalWaterAmount / recipe.beanWeightGrams
        : 0.0;

    return Card(
      elevation: 4,
      shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              'Ratio',
              '1:${ratio.toStringAsFixed(1)}',
            ),
            _buildSummaryItem(
              'Total Water',
              '${recipe.totalWaterAmount.toStringAsFixed(1)}ml',
            ),
            _buildSummaryItem(
              'Bean',
              '${recipe.beanWeightGrams.toStringAsFixed(1)}g',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
