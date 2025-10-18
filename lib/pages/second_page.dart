import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scatter3d_community/pages/home_page_model.dart';
import 'package:scatter3d_community/projects/project_provider.dart';
import 'package:scatter3d_community/utils/daialog.dart';
import 'package:scatter3d_community/utils/scatter_plot_widget.dart';
import 'package:scatter3d_community/utils/snackbars.dart';


class SecondPage extends StatefulWidget {
  final dynamic scatterData;
  final dynamic parsedData;
  final String? csvFilePath;
  final HomePageModel homePageModel;

  const SecondPage({
    super.key,
    required this.scatterData,
    required this.parsedData,
    required this.csvFilePath,
    required this.homePageModel,
  });

  @override
  SecondPageState createState() => SecondPageState();
}

class SecondPageState extends State<SecondPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  ProjectProvider? _projectProvider;
  List<dynamic>? scores;
  bool _isSaving = false;

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
      'value': [
        double.tryParse(item['x'].toString()) ?? 0.0,
        double.tryParse(item['y'].toString()) ?? 0.0,
        double.tryParse(item['z'].toString()) ?? 0.0,
      ],
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

    if (widget.homePageModel.temporaryCsvFile == null) {
      FailureSnackBar.show("CSVファイルが選択されていません");
      return;
    }

    final shouldSave = await showAlertDialog(
      context: context,
      title: "保存しますか？",
      content: "プロジェクトをCloud Storageに保存します",
    );

    if (shouldSave == true) {
      setState(() {
        _isSaving = true;
      });

      try {
        final model = widget.homePageModel;
        final csvFile = model.temporaryCsvFile!;

        // Cloud Storageにアップロード
        await _projectProvider!.uploadCSVAndAddProject(
          csvFile,
          model.scatterTitle.isNotEmpty ? model.scatterTitle : 'Untitled Project',
          xLegend: model.xLegend,
          xMin: model.xMin,
          xMax: model.xMax,
          yLegend: model.yLegend,
          yMin: model.yMin,
          yMax: model.yMax,
          zLegend: model.zLegend,
          zMin: model.zMin,
          zMax: model.zMax,
        );

        // プロジェクト一覧を再読み込み
        await _projectProvider!.loadProjects();

        // 一時データをクリア
        model.clearTemporaryData();

        if (!mounted) return;
        SuccessSnackBar.show('プロジェクトを保存しました');
        Navigator.popUntil(context, ModalRoute.withName('/topPage'));
      } catch (e) {
        if (!mounted) return;
        FailureSnackBar.show('保存に失敗しました: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          elevation: 6,
          shadowColor: Colors.blueGrey[50],
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8))),
          title: const Text("プレビュー"),
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
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveData,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? '保存中...' : 'Cloud Storageに保存'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _isSaving ? null : () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('設定ページに戻る'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}