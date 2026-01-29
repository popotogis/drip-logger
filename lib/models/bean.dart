/// コーヒー豆の情報を表すモデルクラス
///
/// 豆の名称、焙煎所、焙煎度、産地などの基本情報を保持します。
class Bean {
  /// 豆のID (UUID v4などを想定)
  final String id;

  /// 豆の名前 (例: "エチオピア イルガチェフェ")
  final String name;

  /// 焙煎所・店舗名 (例: "Blue Bottle Coffee")
  final String roaster;

  /// 焙煎度 (例: "Light", "Medium", "Dark" / "浅煎り", "中煎り", "深煎り")
  final String roastLevel;

  /// 産地 (例: "Ethiopia", "Colombia")
  final String origin;

  // final String process; // e.g. Washed, Natural (将来的に拡張予定)

  /// 最後に使用した日時 (リストの並び替えなどで使用)
  final DateTime lastUsed;

  Bean({
    required this.id,
    required this.name,
    this.roaster = '',
    this.roastLevel = '',
    this.origin = '',
    DateTime? lastUsed,
  }) : lastUsed = lastUsed ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'roaster': roaster,
        'roastLevel': roastLevel,
        'origin': origin,
        'lastUsed': lastUsed.toIso8601String(),
      };

  factory Bean.fromJson(Map<String, dynamic> json) {
    return Bean(
      id: json['id'] as String,
      name: json['name'] as String,
      roaster: json['roaster'] as String? ?? '',
      roastLevel: json['roastLevel'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
