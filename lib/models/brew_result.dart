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
    buffer.writeln('# ${recipe.name}');
    buffer.writeln('');

    // Bean Info
    buffer.writeln('## 豆の情報');
    if (bean != null) {
      buffer.writeln('- **名称**: ${bean!.name}');
      buffer.writeln('- **焙煎所**: ${bean!.roaster}');
      final originVariety = [
        if (bean!.origin.isNotEmpty) bean!.origin,
        if (bean!.variety != null && bean!.variety!.isNotEmpty) bean!.variety,
      ].join(' / ');
      buffer.writeln(
          '- **産地/品種**: ${originVariety.isEmpty ? "-" : originVariety}');
      buffer.writeln('- **焙煎度**: ${bean!.roastLevel}');
      buffer.writeln('- **精製方法**: ${bean!.process ?? "-"}');
    } else {
      buffer.writeln('- **名称**: -');
      buffer.writeln('- **焙煎所**: -');
      buffer.writeln('- **産地/品種**: -');
      buffer.writeln('- **焙煎度**: -');
      buffer.writeln('- **精製方法**: -');
    }
    buffer.writeln('');

    // Extraction Params
    buffer.writeln('## 抽出パラメータ');
    buffer.writeln(
        '- **使用量**: 豆 ${recipe.beanWeightGrams}g / 湯 ${recipe.totalWaterAmount}ml');
    buffer.writeln('- **挽き目**: ${recipe.grindSize} (${recipe.grinder ?? "-"})');
    buffer
        .writeln('- **温度**: ${recipe.temperature?.toStringAsFixed(1) ?? "-"}℃');
    final gear = [
      if (recipe.dripper != null && recipe.dripper!.isNotEmpty) recipe.dripper,
      if (recipe.filter != null && recipe.filter!.isNotEmpty) recipe.filter,
    ].join(' / ');
    buffer.writeln('- **器具**: ${gear.isEmpty ? "-" : gear}');
    buffer.writeln('');

    // Extraction Result
    buffer.writeln('## 抽出結果 (実績)');
    final plannedTotalSeconds =
        recipe.steps.fold(0, (sum, s) => sum + s.waitTime.inSeconds);
    buffer.writeln(
        '- **合計時間**: ${_formatDuration(totalTime)} (計画: ${_formatDuration(Duration(seconds: plannedTotalSeconds))})');
    buffer.writeln(
        '- **抽出日**: ${brewedAt.year}/${brewedAt.month.toString().padLeft(2, '0')}/${brewedAt.day.toString().padLeft(2, '0')}');
    buffer.writeln('');

    // Step Details
    buffer.writeln('### 抽出ペース詳細');
    buffer.writeln('| Step | 湯量 | 計画時間 | 実績時間 | 差異 |');
    buffer.writeln('| :--- | :--- | :--- | :--- | :--- |');

    for (var step in steps) {
      final diff = step.actualTime.inSeconds - step.plannedTime.inSeconds;
      final diffStr = diff == 0 ? '±0' : (diff > 0 ? '+$diff' : '$diff');
      buffer.writeln(
          '| ${step.stepIndex + 1} | ${step.waterAmount}ml | ${step.plannedTime.inSeconds}s | ${step.actualTime.inSeconds}s | ${diffStr}s |');
    }
    buffer.writeln('');

    // Notes
    buffer.writeln('## テイスティングノート / メモ');
    buffer.writeln('> ${notes.isEmpty ? "-" : notes}');

    return buffer.toString();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
