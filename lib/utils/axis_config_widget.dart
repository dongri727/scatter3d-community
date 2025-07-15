import 'package:flutter/material.dart';
import 'package:scatter3d_community/utils/text_fieald.dart';


class AxisConfigWidget extends StatefulWidget{
  const AxisConfigWidget({
    super.key,
    required this.axisLabel, // x, y, zのいずれかが入力される
    required this.legend, // 各軸の項目名
    required this.minVal, // 各軸の最小値
    required this.maxVal, // 各軸の最大値
    required this.onLegendChanged,
    required this.onMinValChanged,
    required this.onMaxValChanged,
  });

  final String axisLabel;
  final String legend;
  final double minVal;
  final double maxVal;
  final Function(String) onLegendChanged;
  final Function(double) onMinValChanged;
  final Function(double) onMaxValChanged;

  static bool validateFormKey(GlobalKey<FormState> formKey) {
    return formKey.currentState?.validate() ?? false;
  }

  @override
  State<AxisConfigWidget> createState() => _AxisConfigState();
}

class _AxisConfigState extends State<AxisConfigWidget>{

  double? _minMin;
  double? _maxMax;

  @override
  Widget build(BuildContext content){
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.axisLabel}${"軸の設定"}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          MyTextField(
            label: '${widget.axisLabel}${"軸名"}',
            hintText: '${widget.axisLabel}${"軸の名称を入力してください"}',
            initialValue: widget.legend,
            onChanged: widget.onLegendChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "必須項目です";
              }
              return null;
            },
          ),
          Row(
            children: [
              Flexible(
                child: MyTextField(
                  label: '${widget.axisLabel}${"軸目盛りの最小値"}',
                  hintText: 'e.g. -3.5',
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null) {
                      setState(() {
                        _minMin = parsed;
                      });
                      widget.onMinValChanged(parsed);
                    }
                  },
                  keyboardType: const TextInputType.numberWithOptions(signed: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      widget.onMinValChanged(0.0);
                    }
                    if (double.tryParse(value!) == null) {
                      return "数値を入力してください";
                    }
                    return null;
                  },
                ),
              ),
              Flexible(
                child: MyTextField(
                  label: '${widget.axisLabel}${"軸目盛りの最大値"}',
                  hintText: 'e.g. 10',
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null) {
                      setState(() {
                        _maxMax = parsed;
                      });
                      widget.onMaxValChanged(parsed);
                    }
                  },
                  keyboardType: const TextInputType.numberWithOptions(signed: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      widget.onMaxValChanged(0.0);
                      return null;
                    }
                    final parsed = double.tryParse(value);
                    if (double.tryParse(value!) == null) {
                      return "数値を入力してください";
                    }
                    if (_minMin != null && parsed! <= _minMin!) {
                      return "最小値より大きな値";
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}