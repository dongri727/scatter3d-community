import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scatter3d_community/import_csv.dart';
import 'package:scatter3d_community/pages/home_page_model.dart';
import 'package:scatter3d_community/pages/second_page.dart';
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
  final _csvImporter = CsvImporter();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomePageModel>(
      create: (_) => HomePageModel(),
      child: Builder(
        builder: (context) {
          final model = Provider.of<HomePageModel>(context);


          Future<void> handleImportCSV() async {
            final result = await _csvImporter.importCSV(context);
            if (result.parsedData.isNotEmpty) {

              setState(() {
                _parsedData = result.parsedData;
                _csvFilePath = result.filePath;
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
                        onPressed: () {
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
                        icon: const Icon(Icons.file_upload),
                        label: const Text('Import CSV'),
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