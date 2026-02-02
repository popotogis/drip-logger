import 'recipe.dart';
import 'bean.dart';

/// ドリップの実績ステップデータ
///
/// 計画（レシピ）対比での実際の時間を記録します。
class BrewResultStep {
  /// ステップ番号 (0-indexed)
  final int stepIndex;

  /// 計画していた時間
  final Duration plannedTime;

  /// 実際にかかった時間 (ラップタイム)
  final Duration actualTime;

  /// そのステップでの注湯量
  final double waterAmount;

  BrewResultStep({
    required this.stepIndex,
    required this.plannedTime,
    required this.actualTime,
    required this.waterAmount,
  });
}

/// ドリップ全体の実行結果
///
/// レシピ、豆、日時、そして実際の抽出ログをまとめて保持する集約ルート(Aggregate Root)です。
class BrewResult {
  /// 全世界で一意なID
  final String id;

  /// 使用したレシピのスナップショット (レシピ変更の影響を受けないようにコピーを持つ)
  final Recipe recipe;

  /// 使用した豆 (nullの場合は豆指定なし)
  final Bean? bean;

  /// 抽出日時
  final DateTime brewedAt;

  /// 各ステップの実績データ
  final List<BrewResultStep> steps;

  /// 合計抽出時間
  final Duration totalTime;

  /// その回の感想・メモ
  final String notes;

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

    // Recipe Extras
    if (recipe.dripper != null && recipe.dripper!.isNotEmpty) {
      buffer.writeln('Dripper: ${recipe.dripper}');
    }
    if (recipe.grinder != null && recipe.grinder!.isNotEmpty) {
      buffer.writeln('Grinder: ${recipe.grinder}');
    }
    if (recipe.filter != null && recipe.filter!.isNotEmpty) {
      buffer.writeln('Filter: ${recipe.filter}');
    }
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
      if (bean!.process != null && bean!.process!.isNotEmpty) {
        buffer.writeln('Process: ${bean!.process}');
      }
      if (bean!.variety != null && bean!.variety!.isNotEmpty) {
        buffer.writeln('Variety: ${bean!.variety}');
      }
      if (bean!.roastDate != null) {
        buffer.writeln(
            'Roast Date: ${bean!.roastDate.toString().substring(0, 10)}');
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
    return '$minutes:$seconds';
  }
}
