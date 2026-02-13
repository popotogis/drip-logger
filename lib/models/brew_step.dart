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

  /// UI識別用のID (保存はしない、実行時のみ使用)
  /// これがないとReorderableListViewで入力中にフォーカスが外れる
  final String uid;

  static int _uidCounter = 0;

  BrewStep({
    this.type = BrewStepType.pour,
    required this.waterAmount,
    required this.waitTime,
    this.description,
    String? uid,
  }) : uid = uid ?? '${DateTime.now().microsecondsSinceEpoch}_${_uidCounter++}';

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'waterAmount': waterAmount,
        'waitTime': waitTime.inSeconds,
        'description': description,
        // uidは保存しない (毎回生成で良い、あるいは保存しても良いが必須ではない)
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
      // scaleした場合は新しいステップとみなすか？
      // 調整画面でスライダー動かしたときにIDが変わるとフォーカス外れるか？
      // スライダー操作中はTextFieldにフォーカスないから大丈夫か。
      // いや、TextFieldで数値入力中に他が動くことはない。
      // しかし、maintainRatio=trueでBeanWeightを変えると全ステップがscaleされる。
      // その時ステップリストの見た目は変わらない方が良いのでuid維持したいが、
      // BeanWeight変更は「別の操作」なのでフォーカスは関係ない。
      // 逆に、RecipeEditScreenで数値をいじるときはscale呼ばれない。
      uid: uid, // IDを引き継ぐ
    );
  }

  BrewStep copyWith({
    BrewStepType? type,
    double? waterAmount,
    Duration? waitTime,
    String? description,
    String? uid,
  }) {
    return BrewStep(
      type: type ?? this.type,
      waterAmount: waterAmount ?? this.waterAmount,
      waitTime: waitTime ?? this.waitTime,
      description: description ?? this.description,
      uid: uid ?? this.uid,
    );
  }
}
