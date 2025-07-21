import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scatter3d_community/projects/project_model.dart';
import 'package:scatter3d_community/projects/project_provider.dart';
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
  List<dynamic>? scores;

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
        
        if (keys.length >= 3) {
          try {
            final xValue = double.parse(data[keys[0]].toString());
            final yValue = double.parse(data[keys[1]].toString());
            final zValue = double.parse(data[keys[2]].toString());
            
            transformed.add({
              'value': [xValue, yValue, zValue],
              'name': 'Point $i',
              'itemStyle': {'color': '#ff6b6b'},
              'symbolSize': 5,
            });
          } catch (e) {
            print('DEBUG: Error parsing row $i: $e');
          }
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

    final scatterData = ScatterPlotData(
      title: _project!.projectName,
      xAxis: AxisData(
        legend: _project!.xLegend,
        min: _project!.xMin,
        max: _project!.xMax,
      ),
      yAxis: AxisData(
        legend: _project!.yLegend,
        min: _project!.yMin,
        max: _project!.yMax,
      ),
      zAxis: AxisData(
        legend: _project!.zLegend,
        min: _project!.zMin,
        max: _project!.zMax,
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