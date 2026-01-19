import 'brew_step.dart';

// 焙煎度を表す列挙型 (Enum): 値を「浅・中・深」の3つに限定します
enum RoastLevel {
  light, // 浅煎り
  medium, // 中煎り
  dark, // 深煎り
}

// コーヒーの抽出レシピを表すクラス
// ユーザーの指摘により、豆の情報はここには含めず「純粋な淹れ方の手順」として定義します
class Recipe {
  final String id; // ID
  final String name; // レシピ名 ("4:6メソッド"、"浸漬法"など)
  // coffeeBean, roastLevel は削除しました

  final double beanWeightGrams; // 豆の量 (g)
  final String grindSize; // 挽き目 ("中挽き", "30 clicks"など)
  final double? temperature; // 湯温 (℃) [任意: null許可]
  final double totalWaterAmount; // 総湯量 (ml or g)
  final String note; // レシピ自体のメモ ("浅煎り向け"など)
  final List<BrewStep> steps; // 抽出ステップのリスト
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
