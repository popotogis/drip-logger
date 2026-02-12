/// 注湯ステップの種類
enum BrewStepType {
  pour, // 注湯
  wait, // 待機 (蒸らしなど)
  stir, // 攪拌
}

/// ドリップの「1ステップ（1回の注湯）」を表すクラス
///
/// 4:6メソッドなどを表現するために、注湯量と待ち時間のペアを管理します。
class BrewStep {
  /// ステップの種類 (注湯/待機/攪拌)
  final BrewStepType type;

  /// このステップで注ぐお湯の量 (g または ml)
  /// type が wait/stir の場合は基本的に 0 になることを想定
  final double waterAmount;

  /// 注ぎ終わった後の待ち時間 (蒸らし時間やインターバル)
  final Duration waitTime;

  /// 手順の説明 (任意)
  final String? description;

  BrewStep({
    this.type = BrewStepType.pour,
    required this.waterAmount,
    required this.waitTime,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'waterAmount': waterAmount,
        'waitTime': waitTime.inSeconds,
        'description': description,
      };

  factory BrewStep.fromJson(Map<String, dynamic> json) {
    return BrewStep(
      type: json['type'] != null
          ? BrewStepType.values.byName(json['type'])
          : BrewStepType.pour,
      waterAmount: (json['waterAmount'] as num).toDouble(),
      waitTime: Duration(seconds: json['waitTime'] as int),
      description: json['description'] as String?,
    );
  }

  /// 指定した比率で湯量をスケーリングした新しいステップを返します
  BrewStep scale(double ratio) {
    // wait / stir の場合、湯量が0ならそのまま0、万が一入っていてもスケーリングすべきかは議論があるが
    // 待機ステップで湯量があるはずがないので、単純にwaterAmountをスケーリングする
    // ただし、typeは維持する
    final scaledWater = (waterAmount * ratio * 10).roundToDouble() / 10;
    return BrewStep(
      type: type,
      waterAmount: scaledWater,
      waitTime: waitTime,
      description: description,
    );
  }
}
