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

  /// 精製方法（例: "Washed", "Natural"）
  final String? process;

  /// 品種（例: "Geisha", "Bourbon"）
  final String? variety;

  /// 焙煎日
  final DateTime? roastDate;

  /// 最後に使用した日時 (リストの並び替えなどで使用)
  final DateTime lastUsed;

  Bean({
    required this.id,
    required this.name,
    this.roaster = '',
    this.roastLevel = '',
    this.origin = '',
    this.process,
    this.variety,
    this.roastDate,
    DateTime? lastUsed,
  }) : lastUsed = lastUsed ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'roaster': roaster,
        'roastLevel': roastLevel,
        'origin': origin,
        'process': process,
        'variety': variety,
        'roastDate': roastDate?.toIso8601String(),
        'lastUsed': lastUsed.toIso8601String(),
      };

  factory Bean.fromJson(Map<String, dynamic> json) {
    return Bean(
      id: json['id'] as String,
      name: json['name'] as String,
      roaster: json['roaster'] as String? ?? '',
      roastLevel: json['roastLevel'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      process: json['process'] as String?,
      variety: json['variety'] as String?,
      roastDate: json['roastDate'] != null
          ? DateTime.parse(json['roastDate'] as String)
          : null,
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
