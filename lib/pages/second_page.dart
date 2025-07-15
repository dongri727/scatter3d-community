import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scatter3d_community/projects/project_model.dart';
import 'package:scatter3d_community/projects/project_provider.dart';
import 'package:scatter3d_community/utils/daialog.dart';
import 'package:scatter3d_community/utils/scatter_plot_widget.dart';
import 'package:scatter3d_community/utils/snackbars.dart';


class SecondPage extends StatefulWidget {
  final dynamic scatterData;
  final dynamic parsedData;
  final String? csvFilePath;

  const SecondPage({
    super.key, 
    required this.scatterData, 
    required this.parsedData,
    required this.csvFilePath,
  });

  @override
  SecondPageState createState() => SecondPageState();
}

class SecondPageState extends State<SecondPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  ProjectProvider? _projectProvider;
  List<dynamic>? scores;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      _projectProvider?.loadProjects();
    });
  }

  Future<void> _loadData() async {
    // widget.parsedData は List<Map<String,dynamic>> として渡されている前提
    final List<dynamic> transformed = (widget.parsedData as List<Map<String, dynamic>>)
        .map((item) => {
      'value': [item['x'], item['y'], item['z']],
      'name': item['id'],
      'itemStyle': {'color': item['color']},
      'symbolSize': item['size'], // sizeでドットの大きさを個別指定
    })
        .toList();

    setState(() {
      scores = transformed;
    });
  }

  Future<void> _saveData() async {
    _projectProvider ??= Provider.of<ProjectProvider>(context, listen: false);

    if (widget.csvFilePath == null) {
      FailureSnackBar.show("CSVファイルが選択してください");
      return;
    }

    final shouldSave = await showAlertDialog(
      context: context,
      title: "保存しますか？",
      content: "保存後は変更できません",
    );

    if (shouldSave == true) {
      try {
        final newProject = ProjectModel(
          projectName: widget.scatterData.title,
          xLegend: widget.scatterData.xAxis.legend,
          xMax: widget.scatterData.xAxis.max,
          xMin: widget.scatterData.xAxis.min,
          yLegend: widget.scatterData.yAxis.legend,
          yMax: widget.scatterData.yAxis.max,
          yMin: widget.scatterData.yAxis.min,
          zLegend: widget.scatterData.zAxis.legend,
          zMax: widget.scatterData.zAxis.max,
          zMin: widget.scatterData.zAxis.min,
          csvFilePath: widget.csvFilePath,
          jsonData: widget.parsedData,
          isSaved: true,
          createdAt: DateTime.now(),
        );
        await _projectProvider?.addProject(newProject);
        if (!mounted) return; 
        Navigator.popUntil(context, ModalRoute.withName('/topPage'));
      } catch (e) {
        if (!mounted) return;
        FailureSnackBar.show(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 6,
        shadowColor: Colors.blueGrey[50],
        shape:const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(8))),
        title: const Text("Scatter 3D"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(widget.scatterData.title),
              ),
              ScatterPlotWidget(
                scatterData: widget.scatterData,
                scores: scores,
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _saveData();
                },
                icon: const Icon(Icons.save),
                label: Text("保存"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}