import 'package:flutter/material.dart';

class BeanWeightSection extends StatefulWidget {
  final double beanWeight;
  final bool maintainRatio;
  final Function(double) onWeightChanged;
  final Function(bool) onMaintainRatioChanged;

  const BeanWeightSection({
    super.key,
    required this.beanWeight,
    required this.maintainRatio,
    required this.onWeightChanged,
    required this.onMaintainRatioChanged,
  });

  @override
  State<BeanWeightSection> createState() => _BeanWeightSectionState();
}

class _BeanWeightSectionState extends State<BeanWeightSection> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.beanWeight.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant BeanWeightSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 外部（親Widget）からの変更があり、かつ現在入力中の値と異なる場合のみ同期する
    // これにより、入力中のカーソル位置飛びなどを防ぐ
    if (oldWidget.beanWeight != widget.beanWeight) {
      final currentVal = double.tryParse(_controller.text);
      if (currentVal != widget.beanWeight) {
        // 数値として異なる場合のみ更新（"15." と "15" のようなケースでの上書き防止は
        // パース結果の比較である程度カバーできるが、完全ではない。
        // ここでは「外部からの大きな変更（例：レシピリセット）」を優先し、
        // 微細な入力中の整合性は onWeightChanged 側のロジックに委ねる。
        // ただし、入力中に親が再ビルドされただけで値が変わっていない場合はここに入らないので安全。
        _controller.text = widget.beanWeight.toString();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BEAN WEIGHT',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                // Keyには値を含めない
                key: const ValueKey('bean_weight_input'),
                controller: _controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  suffixText: 'g',
                  border: OutlineInputBorder(),
                  errorMaxLines: 2,
                ),
                validator: (val) {
                  final d = double.tryParse(val ?? '');
                  if (d == null || d <= 0) return 'Invalid';
                  if (d > 1000) return 'Too large';
                  return null;
                },
                onChanged: (val) {
                  final weight = double.tryParse(val) ?? 0;
                  if (weight > 0) widget.onWeightChanged(weight);
                },
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                const Text('Scale Steps', style: TextStyle(fontSize: 12)),
                Switch(
                  value: widget.maintainRatio,
                  onChanged: widget.onMaintainRatioChanged,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
