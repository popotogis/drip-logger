import 'recipe.dart';
import 'bean.dart';

/// ドリップの実績ステップデータ
class BrewResultStep {
  final int stepIndex;
  final Duration plannedTime;
  final Duration actualTime; // 実際にかかった時間 (ラップタイム)
  final double waterAmount; // そのステップでの注湯量

  BrewResultStep({
    required this.stepIndex,
    required this.plannedTime,
    required this.actualTime,
    required this.waterAmount,
  });
}

/// ドリップ全体の実行結果
class BrewResult {
  final String id;
  final Recipe recipe; // 使用したレシピのスナップショット
  final Bean? bean; // 使用した豆
  final DateTime brewedAt;
  final List<BrewResultStep> steps;
  final Duration totalTime;
  final String notes; // その回の感想など

  BrewResult({
    required this.id,
    required this.recipe,
    this.bean,
    required this.brewedAt,
    required this.steps,
    required this.totalTime,
    this.notes = '',
  });

  BrewResult copyWith({
    String? id,
    Recipe? recipe,
    Bean? bean,
    DateTime? brewedAt,
    List<BrewResultStep>? steps,
    Duration? totalTime,
    String? notes,
  }) {
    return BrewResult(
      id: id ?? this.id,
      recipe: recipe ?? this.recipe,
      bean: bean ?? this.bean,
      brewedAt: brewedAt ?? this.brewedAt,
      steps: steps ?? this.steps,
      totalTime: totalTime ?? this.totalTime,
      notes: notes ?? this.notes,
    );
  }

  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# Brew Result: ${recipe.name}');
    buffer.writeln('Date: ${brewedAt.toString().substring(0, 16)}');
    buffer.writeln('Total Time: ${_formatDuration(totalTime)}');
    buffer.writeln('');

    // Bean Info
    if (bean != null) {
      buffer.writeln('## Bean');
      buffer.writeln('Name: ${bean!.name}');
      if (bean!.roaster.isNotEmpty) buffer.writeln('Roaster: ${bean!.roaster}');
      if (bean!.origin.isNotEmpty) buffer.writeln('Origin: ${bean!.origin}');
      if (bean!.roastLevel.isNotEmpty) {
        buffer.writeln('Roast: ${bean!.roastLevel}');
      }
      buffer.writeln('');
    }

    buffer.writeln('## Details');
    buffer.writeln('| Step | Water | Time (Plan) | Time (Actual) |');
    buffer.writeln('|---|---|---|---|');

    for (var step in steps) {
      buffer.writeln(
          '| ${step.stepIndex + 1} | ${step.waterAmount}ml | ${step.plannedTime.inSeconds}s | ${_formatDuration(step.actualTime)} |');
    }

    if (notes.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('## Notes');
      buffer.writeln(notes);
    }

    return buffer.toString();
  }
// ... rest of class (helper) ...

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
