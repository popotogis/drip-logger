// ドリップの「1ステップ（1回の注湯）」を表すクラス
class BrewStep {
  // このステップで注ぐお湯の量 (g または ml)
  final double waterAmount;

  // 注ぎ終わった後の待ち時間 (蒸らし時間やインターバル)
  // Duration は「時間の間隔」を扱うFlutter(Dart)の便利な型です
  final Duration waitTime;

  BrewStep({
    required this.waterAmount,
    required this.waitTime,
  });

  Map<String, dynamic> toJson() => {
        'waterAmount': waterAmount,
        'waitTime': waitTime.inSeconds,
      };

  factory BrewStep.fromJson(Map<String, dynamic> json) {
    return BrewStep(
      waterAmount: (json['waterAmount'] as num).toDouble(),
      waitTime: Duration(seconds: json['waitTime'] as int),
    );
  }
}
