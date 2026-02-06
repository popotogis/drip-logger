import 'package:flutter/material.dart';
import '../../models/brew_step.dart';

class StepEditList extends StatelessWidget {
  final List<BrewStep> steps;
  final Function(int index, double value) onWaterChanged;
  final Function(int index, int value) onWaitTimeChanged;

  const StepEditList({
    super.key,
    required this.steps,
    required this.onWaterChanged,
    required this.onWaitTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        return _StepInputRow(
          // Keyをindexベースにして、値が変わってもWidget自体は再利用されるようにする
          key: ValueKey('step_row_$index'),
          index: index,
          step: step,
          onWaterChanged: onWaterChanged,
          onWaitTimeChanged: onWaitTimeChanged,
        );
      },
    );
  }
}

class _StepInputRow extends StatefulWidget {
  final int index;
  final BrewStep step;
  final Function(int index, double value) onWaterChanged;
  final Function(int index, int value) onWaitTimeChanged;

  const _StepInputRow({
    super.key,
    required this.index,
    required this.step,
    required this.onWaterChanged,
    required this.onWaitTimeChanged,
  });

  @override
  State<_StepInputRow> createState() => _StepInputRowState();
}

class _StepInputRowState extends State<_StepInputRow> {
  late TextEditingController _waterController;
  late TextEditingController _timeController;

  @override
  void initState() {
    super.initState();
    _waterController = TextEditingController(
      text: widget.step.waterAmount.toStringAsFixed(1),
    );
    _timeController = TextEditingController(
      text: widget.step.waitTime.inSeconds.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _StepInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update Water Amount
    if (oldWidget.step.waterAmount != widget.step.waterAmount) {
      final currentVal = double.tryParse(_waterController.text);
      // 差分が大きい場合（数値として異なり、かつフォーマット後も異なる場合）のみ更新
      // 単純なdouble比較だと入力中の "15." などで消える可能性があるため
      // toStringAsFixed(1) で比較して、表示上の値が変わるべき時のみ更新する
      // ただし、ここは「比率維持」で自動計算された値が入ってくるケースを想定
      if (currentVal != widget.step.waterAmount) {
        // 入力中でない、あるいは外部からの強制更新（比率変更など）とみなして更新
        // 厳密には「フォーカスを持っているか」も判定できるとベストだが、
        // 「値が外部から変わった」＝「比率維持計算が走った」とみなして更新する
        // ユーザーが入力してViewModelが変わった直後のRebuildでは、
        // 通常値は同じはずなのでここには入らない
        // （ViewModelがパースミスなどで元の値に戻した場合は入るが、それは正しい挙動）
        _waterController.text = widget.step.waterAmount.toStringAsFixed(1);
      }
    }

    // Update Wait Time
    if (oldWidget.step.waitTime != widget.step.waitTime) {
      final currentVal = int.tryParse(_timeController.text);
      if (currentVal != widget.step.waitTime.inSeconds) {
        _timeController.text = widget.step.waitTime.inSeconds.toString();
      }
    }
  }

  @override
  void dispose() {
    _waterController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 14,
          child:
              Text('${widget.index + 1}', style: const TextStyle(fontSize: 12)),
        ),
        title: Row(
          children: [
            const Text('Water: '),
            Expanded(
              child: TextFormField(
                controller: _waterController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  isDense: true,
                  suffixText: 'ml',
                ),
                onChanged: (val) {
                  final water = double.tryParse(val) ?? 0;
                  widget.onWaterChanged(widget.index, water);
                },
              ),
            ),
          ],
        ),
        trailing: SizedBox(
          width: 60,
          child: TextFormField(
            controller: _timeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              isDense: true,
              suffixText: 's',
            ),
            onChanged: (val) {
              final seconds = int.tryParse(val) ?? 0;
              widget.onWaitTimeChanged(widget.index, seconds);
            },
          ),
        ),
      ),
    );
  }
}
