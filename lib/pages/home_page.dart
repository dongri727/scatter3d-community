import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scatter3d_community/pages/home_page_model.dart';
import 'package:scatter3d_community/pages/second_page.dart';
import 'package:scatter3d_community/projects/project_provider.dart';
import 'package:scatter3d_community/utils/axis_config_widget.dart';
import 'package:scatter3d_community/utils/snackbars.dart';
import 'package:scatter3d_community/utils/text_fieald.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  bool _showValidation = false;
  List<Map<String, dynamic>>? _parsedData;
  List<Map<String, dynamic>>? scatterData;
  String? _csvFilePath;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomePageModel>(
      create: (_) => HomePageModel(),
      child: Builder(
        builder: (context) {
          final model = Provider.of<HomePageModel>(context);


          Future<void> handleImportCSV() async {
            try {
              setState(() {
                _isUploading = true;
              });

              // ファイルを選択
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['csv'],
              );

              if (result != null && result.files.single.path != null) {
                final File csvFile = File(result.files.single.path!);
                if (!context.mounted) return;
                final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
                
                // Cloud StorageにCSVファイルをアップロード
                await projectProvider.uploadCSVAndAddProject(
                  csvFile,
                  model.scatterTitle.isNotEmpty ? model.scatterTitle : 'Untitled Project'
                );
                
                // アップロード成功後、プロジェクト一覧を再読み込み
                await projectProvider.loadProjects();
                
                SuccessSnackBar.show('CSVファイルがアップロードされました');
                
                // 最新のプロジェクトを取得して表示データを設定
                final projects = projectProvider.projects;
                if (projects.isNotEmpty) {
                  final latestProject = projects.last;
                  setState(() {
                    _parsedData = latestProject.jsonData;
                    _csvFilePath = latestProject.csvFilePath;
                  });
                }
              } else {
                FailureSnackBar.show('ファイルの選択がキャンセルされました');
              }
            } catch (e) {
              FailureSnackBar.show('アップロードに失敗しました: $e');
            } finally {
              setState(() {
                _isUploading = false;
              });
            }
          }

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              elevation: 6,
              shadowColor: Colors.blueGrey[50],
              shape:const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(8))),
              title: Text("基本設定とファイル選択"),
            ),
            body: Center(
              child: Form(
                key: _formKey,
                autovalidateMode: _showValidation
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      MyTextField(
                        label: "タイトル",
                        hintText: "プロジェクト名を入力してください",
                        onChanged: (value) {
                          model.setScatterTitle(value);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "必須項目です";
                          }
                          return null;
                        },
                      ),
                      AxisConfigWidget(
                        axisLabel: 'x',
                        legend: model.xLegend,
                        minVal: model.xMin,
                        maxVal: model.xMax,
                        onLegendChanged: (value) => model.setXLegend(value),
                        onMinValChanged: (value) => model.setXMin(value),
                        onMaxValChanged: (value) => model.setXMax(value),
                      ),
                      AxisConfigWidget(
                        axisLabel: 'y',
                        legend: model.yLegend,
                        minVal: model.yMin,
                        maxVal: model.yMax,
                        onLegendChanged: (value) => model.setYLegend(value),
                        onMinValChanged: (value) => model.setYMin(value),
                        onMaxValChanged: (value) => model.setYMax(value),
                      ),
                      AxisConfigWidget(
                        axisLabel: 'z',
                        legend: model.zLegend,
                        minVal: model.zMin,
                        maxVal: model.zMax,
                        onLegendChanged: (value) => model.setZLegend(value),
                        onMinValChanged: (value) => model.setZMin(value),
                        onMaxValChanged: (value) => model.setZMax(value),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : () {
                          setState(() {
                            _showValidation = true;
                          });
                          if (_formKey.currentState!.validate()) {
                            if (model.xMax > model.xMin &&
                                model.yMax > model.yMin &&
                                model.zMax > model.zMin) {
                              handleImportCSV();
                            } else {
                              FailureSnackBar.show(
                                  "目盛りの設定に不備があります");
                            }
                          } else {
                            FailureSnackBar.show(
                                "入力に不備があります");
                          }
                        },
                        icon: _isUploading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)
                            )
                          : const Icon(Icons.cloud_upload),
                        label: Text(_isUploading ? 'アップロード中...' : 'Upload CSV to Cloud'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                // Providerから集約済みのscatterDataを取得してSecondPageへ
                final scatterData = model.scatterPlotData;
                if (_parsedData != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(

                      builder: (context) => SecondPage(
                        scatterData: scatterData,
                        parsedData: _parsedData!,
                        csvFilePath: _csvFilePath,
                      ),

                    ),
                  );
                } else {
                  FailureSnackBar.show("CSVファイルが読み込まれていません");
                }
              },
              child: const Icon(Icons.last_page),
            ),
          );
        },
      ),
    );
  }
}