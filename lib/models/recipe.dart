import 'brew_step.dart';

/// 焙煎度を表す列挙型 (Enum)
///
/// 単純化のため、値を「浅・中・深」の3つに限定しています。
enum RoastLevel {
  light, // 浅煎り
  medium, // 中煎り
  dark, // 深煎り
}

/// コーヒーの抽出レシピを表すクラス
///
/// 豆の情報は含めず、「純粋な淹れ方の手順」として定義します。
class Recipe {
  /// レシピのID
  final String id;

  /// レシピ名 (例: "4:6メソッド"、"浸漬法"など)
  final String name;

  /// 使用する豆の量 (g)
  final double beanWeightGrams;

  /// 挽き目 (例: "中挽き", "30 clicks"など)
  final String grindSize;

  /// 湯温 (℃) [任意]
  final double? temperature;

  /// 総湯量 (ml or g)
  final double totalWaterAmount;

  /// レシピ自体のメモ (例: "浅煎り向け"など)
  final String note;

  /// 抽出ステップのリスト
  final List<BrewStep> steps;

  /// 最後に使用した日時
  final DateTime lastUsed;

  Recipe({
    required this.id,
    required this.name,
    required this.beanWeightGrams,
    required this.grindSize,
    this.temperature, // requiredではない (= nullでもOK)
    required this.totalWaterAmount,
    this.note = '', // デフォルトは空文字
    required this.steps,
    DateTime? lastUsed,
  }) : lastUsed = lastUsed ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'beanWeightGrams': beanWeightGrams,
        'grindSize': grindSize,
        'temperature': temperature,
        'totalWaterAmount': totalWaterAmount,
        'note': note,
        'steps': steps.map((s) => s.toJson()).toList(),
        'lastUsed': lastUsed.toIso8601String(),
      };

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String,
      beanWeightGrams: (json['beanWeightGrams'] as num).toDouble(),
      grindSize: json['grindSize'] as String,
      temperature: (json['temperature'] as num?)?.toDouble(),
      totalWaterAmount: (json['totalWaterAmount'] as num).toDouble(),
      note: json['note'] as String? ?? '',
      steps: (json['steps'] as List)
          .map((e) => BrewStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
