import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scatter3d_community/projects/project_model.dart';
import 'package:scatter3d_community/projects/project_provider.dart';
import 'package:scatter3d_community/projects/axis_config_model.dart';
import 'package:scatter3d_community/services/firebase_storage_service.dart';
import 'package:scatter3d_community/utils/scatter_plot_widget.dart';
import 'package:scatter3d_community/utils/snackbars.dart';


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