import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scatter3d_community/projects/project_model.dart';
import 'package:scatter3d_community/projects/project_provider.dart';
import 'package:scatter3d_community/projects/axis_config_model.dart';
import 'package:scatter3d_community/services/firebase_storage_service.dart';
import 'package:scatter3d_community/utils/scatter_plot_widget.dart';
import 'package:scatter3d_community/utils/snackbars.dart';
import 'package:scatter3d_community/utils/axis_config_widget.dart';


class PreviewPage extends StatefulWidget {
  final String projectKey;

  const PreviewPage({
    super.key,
    required this.projectKey,
  });

  @override
  PreviewPageState createState() => PreviewPageState();
}

class PreviewPageState extends State<PreviewPage> {
  ProjectProvider? _projectProvider;
  ProjectModel? _project;
  ProjectAxisConfig? _axisConfig;
  List<dynamic>? scores;
  final FirebaseStorageService _storageService = FirebaseStorageService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      _projectProvider?.loadProjects();
      _loadData();
    });
  }

  Future<void> _showEditAxisDialog() async {
    if (_project == null) return;

    // 現在の軸設定を取得
    final currentXLegend = _axisConfig?.xAxis.legend ?? _project!.xLegend;
    final currentXMin = _axisConfig?.xAxis.min ?? _project!.xMin;
    final currentXMax = _axisConfig?.xAxis.max ?? _project!.xMax;
    final currentYLegend = _axisConfig?.yAxis.legend ?? _project!.yLegend;
    final currentYMin = _axisConfig?.yAxis.min ?? _project!.yMin;
    final currentYMax = _axisConfig?.yAxis.max ?? _project!.yMax;
    final currentZLegend = _axisConfig?.zAxis.legend ?? _project!.zLegend;
    final currentZMin = _axisConfig?.zAxis.min ?? _project!.zMin;
    final currentZMax = _axisConfig?.zAxis.max ?? _project!.zMax;

    // 編集用の変数
    String xLegend = currentXLegend;
    double xMin = currentXMin;
    double xMax = currentXMax;
    String yLegend = currentYLegend;
    double yMin = currentYMin;
    double yMax = currentYMax;
    String zLegend = currentZLegend;
    double zMin = currentZMin;
    double zMax = currentZMax;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('軸設定を編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AxisConfigWidget(
                axisLabel: 'x',
                legend: currentXLegend,
                minVal: currentXMin,
                maxVal: currentXMax,
                onLegendChanged: (value) => xLegend = value,
                onMinValChanged: (value) => xMin = value,
                onMaxValChanged: (value) => xMax = value,
              ),
              AxisConfigWidget(
                axisLabel: 'y',
                legend: currentYLegend,
                minVal: currentYMin,
                maxVal: currentYMax,
                onLegendChanged: (value) => yLegend = value,
                onMinValChanged: (value) => yMin = value,
                onMaxValChanged: (value) => yMax = value,
              ),
              AxisConfigWidget(
                axisLabel: 'z',
                legend: currentZLegend,
                minVal: currentZMin,
                maxVal: currentZMax,
                onLegendChanged: (value) => zLegend = value,
                onMinValChanged: (value) => zMin = value,
                onMaxValChanged: (value) => zMax = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _saveAxisConfig(xLegend, xMin, xMax, yLegend, yMin, yMax, zLegend, zMin, zMax);
    }
  }

  Future<void> _createDefaultAxisConfigFromData() async {
    if (_project == null || _project!.jsonData.isEmpty) return;

    try {
      // データから最小値・最大値を計算
      double xMin = double.infinity;
      double xMax = double.negativeInfinity;
      double yMin = double.infinity;
      double yMax = double.negativeInfinity;
      double zMin = double.infinity;
      double zMax = double.negativeInfinity;

      for (final data in _project!.jsonData) {
        final xValue = double.tryParse(data['x']?.toString() ?? '0') ?? 0.0;
        final yValue = double.tryParse(data['y']?.toString() ?? '0') ?? 0.0;
        final zValue = double.tryParse(data['z']?.toString() ?? '0') ?? 0.0;

        if (xValue < xMin) xMin = xValue;
        if (xValue > xMax) xMax = xValue;
        if (yValue < yMin) yMin = yValue;
        if (yValue > yMax) yMax = yValue;
        if (zValue < zMin) zMin = zValue;
        if (zValue > zMax) zMax = zValue;
      }

      // マージンを追加（範囲の10%）
      final xMargin = (xMax - xMin) * 0.1;
      final yMargin = (yMax - yMin) * 0.1;
      final zMargin = (zMax - zMin) * 0.1;

      xMin -= xMargin;
      xMax += xMargin;
      yMin -= yMargin;
      yMax += yMargin;
      zMin -= zMargin;
      zMax += zMargin;

      print('DEBUG: Calculated ranges - X: [$xMin, $xMax], Y: [$yMin, $yMax], Z: [$zMin, $zMax]');

      // 軸設定を作成して保存
      final now = DateTime.now();
      final newAxisConfig = ProjectAxisConfig(
        projectName: _project!.projectName,
        xAxis: AxisConfig(legend: _project!.xLegend, min: xMin, max: xMax),
        yAxis: AxisConfig(legend: _project!.yLegend, min: yMin, max: yMax),
        zAxis: AxisConfig(legend: _project!.zLegend, min: zMin, max: zMax),
        createdAt: now,
        updatedAt: now,
      );

      await _projectProvider!.updateProjectAxisConfig(_project!, newAxisConfig);

      setState(() {
        _axisConfig = newAxisConfig;
      });

      print('DEBUG: Default axis config created and saved');
    } catch (e) {
      print('DEBUG: Error creating default axis config: $e');
    }
  }

  Future<void> _saveAxisConfig(
    String xLegend, double xMin, double xMax,
    String yLegend, double yMin, double yMax,
    String zLegend, double zMin, double zMax,
  ) async {
    try {
      if (_project == null) return;

      final now = DateTime.now();
      final newAxisConfig = ProjectAxisConfig(
        projectName: _project!.projectName,
        xAxis: AxisConfig(legend: xLegend, min: xMin, max: xMax),
        yAxis: AxisConfig(legend: yLegend, min: yMin, max: yMax),
        zAxis: AxisConfig(legend: zLegend, min: zMin, max: zMax),
        createdAt: _axisConfig?.createdAt ?? now,
        updatedAt: now,
      );

      await _projectProvider!.updateProjectAxisConfig(_project!, newAxisConfig);

      // 軸設定を更新してグラフを再描画
      setState(() {
        _axisConfig = newAxisConfig;
      });

      SuccessSnackBar.show('軸設定を保存しました');
    } catch (e) {
      FailureSnackBar.show('保存に失敗しました: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      if (_projectProvider == null) return;
      print('DEBUG: Looking for project with key: ${widget.projectKey}');
      print('DEBUG: Available projects: ${_projectProvider!.projects.map((p) => p.storageRef).toList()}');

      _project = _projectProvider!.getProjectByStorageRef(widget.projectKey);

      if (_project == null) {
        print('DEBUG: Project not found for storageRef: ${widget.projectKey}');
        FailureSnackBar.show('Project not found');
        return;
      }

      print('DEBUG: Found project: ${_project!.projectName}');
      print('DEBUG: Project jsonData length: ${_project!.jsonData.length}');

      // 軸設定ファイルを読み込み
      if (_project!.storageRef != null) {
        final fileName = _project!.storageRef!.split('/').last;
        final configPath = _storageService.getAxisConfigPath(fileName);
        _axisConfig = await _storageService.downloadAxisConfigFile(configPath);
        print('DEBUG: Axis config loaded: ${_axisConfig != null}');
        if (_axisConfig != null) {
          print('DEBUG: X axis: ${_axisConfig!.xAxis.legend} (${_axisConfig!.xAxis.min} - ${_axisConfig!.xAxis.max})');
          print('DEBUG: Y axis: ${_axisConfig!.yAxis.legend} (${_axisConfig!.yAxis.min} - ${_axisConfig!.yAxis.max})');
          print('DEBUG: Z axis: ${_axisConfig!.zAxis.legend} (${_axisConfig!.zAxis.min} - ${_axisConfig!.zAxis.max})');
        } else {
          // 軸設定ファイルが存在しない場合、データから自動計算して作成
          print('DEBUG: Axis config not found, creating default from data');
          await _createDefaultAxisConfigFromData();
        }
      }
      
      if (_project!.csvFilePath == null) {
        FailureSnackBar.show('CSV path not found');
        return;
      }

      // Use stored JSON data
      final List<Map<String, dynamic>> parsedData = List<Map<String, dynamic>>.from(_project!.jsonData);
      print('DEBUG: parsedData length: ${parsedData.length}');
      print('DEBUG: first item: ${parsedData.isNotEmpty ? parsedData.first : "empty"}');
      
      if (parsedData.isEmpty) {
        print('DEBUG: No data to transform');
        setState(() {
          scores = [];
        });
        return;
      }
      
      // CSVの生データを3D座標用に変換
      final List<dynamic> transformed = [];
      for (int i = 0; i < parsedData.length; i++) {
        final data = parsedData[i];
        final keys = data.keys.toList();
        print('DEBUG: Row $i keys: $keys');
        print('DEBUG: Row $i data: $data');
        
        // 正しくx,y,z列を特定して数値変換
        try {
          final xValue = double.tryParse(data['x']?.toString() ?? '0') ?? 0.0;
          final yValue = double.tryParse(data['y']?.toString() ?? '0') ?? 0.0;
          final zValue = double.tryParse(data['z']?.toString() ?? '0') ?? 0.0;
          
          transformed.add({
            'value': [xValue, yValue, zValue],
            'name': data['id']?.toString() ?? 'Point $i',
            'itemStyle': {'color': '#ff6b6b'},
            'symbolSize': int.tryParse(data['size']?.toString() ?? '5') ?? 5,
          });
        } catch (e) {
          print('DEBUG: Error parsing row $i: $e');
        }
      }
      
      print('DEBUG: transformed length: ${transformed.length}');
      print('DEBUG: first transformed: ${transformed.isNotEmpty ? transformed.first : "empty"}');

      if (!mounted) return;
      setState(() {
        scores = transformed;
      });
    } catch (e) {
      print('DEBUG: Error in _loadData: $e');
      if (!mounted) return;
      FailureSnackBar.show(e.toString());
      Navigator.popUntil(context, ModalRoute.withName('/topPage'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_project == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 軸設定ファイルがあればそれを使用、なければプロジェクトのデフォルト値を使用
    final scatterData = ScatterPlotData(
      title: _project!.projectName,
      xAxis: AxisData(
        legend: _axisConfig?.xAxis.legend ?? _project!.xLegend,
        min: _axisConfig?.xAxis.min ?? _project!.xMin,
        max: _axisConfig?.xAxis.max ?? _project!.xMax,
      ),
      yAxis: AxisData(
        legend: _axisConfig?.yAxis.legend ?? _project!.yLegend,
        min: _axisConfig?.yAxis.min ?? _project!.yMin,
        max: _axisConfig?.yAxis.max ?? _project!.yMax,
      ),
      zAxis: AxisData(
        legend: _axisConfig?.zAxis.legend ?? _project!.zLegend,
        min: _axisConfig?.zAxis.min ?? _project!.zMin,
        max: _axisConfig?.zAxis.max ?? _project!.zMax,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 6,
        shadowColor: Colors.blueGrey[50],
        shape:const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(8))),
        title: const Text('Your Project'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showEditAxisDialog,
            tooltip: '軸設定を編集',
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(_project!.projectName),
            ),
            ScatterPlotWidget(
              scatterData: scatterData,
              scores: scores,
            ),
          ],
        ),
      ),
    );
  }
}

class AxisData {
  final String legend;
  final double min;
  final double max;

  AxisData({
    required this.legend,
    required this.min,
    required this.max,
  });
}

class ScatterPlotData {
  final String title;
  final AxisData xAxis;
  final AxisData yAxis;
  final AxisData zAxis;

  ScatterPlotData({
    required this.title,
    required this.xAxis,
    required this.yAxis,
    required this.zAxis,
  });
}