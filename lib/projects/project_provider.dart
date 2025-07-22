import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:scatter3d_community/projects/project_model.dart';
import 'package:scatter3d_community/projects/axis_config_model.dart';
import 'package:scatter3d_community/services/firebase_storage_service.dart';
import 'package:firebase_storage/firebase_storage.dart';


class ProjectProvider extends ChangeNotifier {
  final FirebaseStorageService _storageService = FirebaseStorageService();
  List<ProjectModel> _projects = [];

  List<ProjectModel> get projects => _projects;

  /// Cloud Storageからプロジェクト一覧を読み込み
  Future<void> loadProjects() async {
    try {
      final List<Reference> csvFiles = await _storageService.listCSVFiles();
      _projects.clear();
      
      for (final ref in csvFiles) {
        try {
          // CSVファイルをダウンロードして解析
          final data = await _storageService.downloadFile(ref.fullPath);
          final csvContent = utf8.decode(data);
          print('DEBUG loadProjects: CSV content length: ${csvContent.length}');
          print('DEBUG loadProjects: First 200 chars: ${csvContent.length > 200 ? csvContent.substring(0, 200) : csvContent}');
          
          // ファイル名からプロジェクト名を取得
          final fileName = ref.name;
          final projectName = fileName.replaceAll('.csv', '');
          
          // CSVデータを解析（改行文字を統一）
          final normalizedCsvContent = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
          print('DEBUG: Normalized content first 200 chars: ${normalizedCsvContent.length > 200 ? normalizedCsvContent.substring(0, 200) : normalizedCsvContent}');
          
          // 手動でCSVを解析
          final lines = normalizedCsvContent.split('\n').where((line) => line.trim().isNotEmpty).toList();
          print('DEBUG: Lines count: ${lines.length}');
          print('DEBUG: First few lines: ${lines.take(3).toList()}');
          
          final List<List<dynamic>> csvData = [];
          for (final line in lines) {
            final row = line.split(',');
            csvData.add(row);
          }
          
          print('DEBUG loadProjects: CSV rows count: ${csvData.length}');
          
          if (csvData.isNotEmpty) {
            final headers = csvData.first.map((e) => e.toString()).toList();
            print('DEBUG loadProjects: Headers: $headers');
            final jsonData = <Map<String, dynamic>>[];
            
            for (int i = 1; i < csvData.length; i++) {
              final row = csvData[i];
              final rowData = <String, dynamic>{};
              for (int j = 0; j < headers.length && j < row.length; j++) {
                rowData[headers[j]] = row[j];
              }
              jsonData.add(rowData);
            }
            
            print('DEBUG loadProjects: JsonData length: ${jsonData.length}');
            print('DEBUG loadProjects: First jsonData item: ${jsonData.isNotEmpty ? jsonData.first : "empty"}');
            
            // プロジェクトモデルを作成
            final project = ProjectModel(
              projectName: projectName,
              xLegend: headers.isNotEmpty ? headers[0] : 'X',
              yLegend: headers.length > 1 ? headers[1] : 'Y',
              zLegend: headers.length > 2 ? headers[2] : 'Z',
              xMax: 100,
              xMin: 0,
              yMax: 100,
              yMin: 0,
              zMax: 100,
              zMin: 0,
              csvFilePath: await ref.getDownloadURL(),
              storageRef: ref.fullPath,
              jsonData: jsonData,
              isSaved: true,
              createdAt: DateTime.now(),
            );
            
            _projects.add(project);
          } else {
            print('DEBUG loadProjects: CSV data is empty for ${ref.name}');
          }
        } catch (e) {
          // 個別のファイル読み込みエラーはログに出力するが、全体の処理は継続
          print('ファイル読み込みエラー (${ref.name}): $e');
        }
      }
      
      notifyListeners();
    } catch (e) {
      throw Exception('プロジェクトの読み込みに失敗しました: $e');
    }
  }

  /// プロジェクトをStorageRefで取得
  ProjectModel? getProjectByStorageRef(String storageRef) {
    try {
      return _projects.firstWhere((project) => project.storageRef == storageRef);
    } catch (e) {
      return null;
    }
  }

  /// CSVファイルをCloud Storageにアップロードしてプロジェクトを追加
  Future<void> uploadCSVAndAddProject(File csvFile, String projectName) async {
    try {
      final fileName = '${projectName}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final downloadUrl = await _storageService.uploadCSVFile(csvFile, fileName);
      
      // CSVファイルを読み取ってプロジェクトデータを生成
      final csvContent = await csvFile.readAsString();
      final normalizedCsvContent = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      
      // 手動でCSVを解析（loadProjectsと同じ方法）
      final lines = normalizedCsvContent.split('\n').where((line) => line.trim().isNotEmpty).toList();
      print('DEBUG uploadCSV: Lines count: ${lines.length}');
      final List<List<dynamic>> csvData = [];
      for (final line in lines) {
        final row = line.split(',');
        csvData.add(row);
      }
      print('DEBUG uploadCSV: CSV rows count: ${csvData.length}');
      
      if (csvData.isNotEmpty) {
        final headers = csvData.first.map((e) => e.toString()).toList();
        final jsonData = <Map<String, dynamic>>[];
        
        for (int i = 1; i < csvData.length; i++) {
          final row = csvData[i];
          final rowData = <String, dynamic>{};
          for (int j = 0; j < headers.length && j < row.length; j++) {
            rowData[headers[j]] = row[j];
          }
          jsonData.add(rowData);
        }
        
        print('DEBUG uploadCSV: JsonData length: ${jsonData.length}');
        print('DEBUG uploadCSV: First jsonData item: ${jsonData.isNotEmpty ? jsonData.first : "empty"}');
        
        // デフォルトの軸設定を作成してアップロード
        final baseFileName = fileName.replaceAll('.csv', '');
        final axisConfig = ProjectAxisConfig.createDefault(
          projectName: projectName,
          headers: headers,
        );
        await _storageService.uploadAxisConfigFile(axisConfig, baseFileName);
        
        final project = ProjectModel(
          projectName: projectName,
          xLegend: axisConfig.xAxis.legend,
          yLegend: axisConfig.yAxis.legend,
          zLegend: axisConfig.zAxis.legend,
          xMax: axisConfig.xAxis.max,
          xMin: axisConfig.xAxis.min,
          yMax: axisConfig.yAxis.max,
          yMin: axisConfig.yAxis.min,
          zMax: axisConfig.zAxis.max,
          zMin: axisConfig.zAxis.min,
          csvFilePath: downloadUrl,
          storageRef: 'users/${_storageService.currentUserId}/csv/$fileName',
          jsonData: jsonData,
          isSaved: true,
          createdAt: DateTime.now(),
        );
        
        _projects.add(project);
        notifyListeners();
      }
    } catch (e) {
      throw Exception('CSVファイルのアップロードに失敗しました: $e');
    }
  }

  /// プロジェクトの軸設定を更新してCloud Storageに保存
  Future<void> updateProjectAxisConfig(ProjectModel project, ProjectAxisConfig axisConfig) async {
    try {
      // プロジェクトのstorageRefからファイル名を取得
      final storageRef = project.storageRef;
      if (storageRef == null) {
        throw Exception('プロジェクトにstorageRefが設定されていません');
      }
      
      final fileName = storageRef.split('/').last.replaceAll('.csv', '');
      await _storageService.uploadAxisConfigFile(axisConfig, fileName);
      
      // ローカルのプロジェクトデータも更新
      final updatedProject = project.copyWith(
        xLegend: axisConfig.xAxis.legend,
        yLegend: axisConfig.yAxis.legend,
        zLegend: axisConfig.zAxis.legend,
        xMax: axisConfig.xAxis.max,
        xMin: axisConfig.xAxis.min,
        yMax: axisConfig.yAxis.max,
        yMin: axisConfig.yAxis.min,
        zMax: axisConfig.zAxis.max,
        zMin: axisConfig.zAxis.min,
      );
      
      final index = _projects.indexWhere((p) => p.storageRef == project.storageRef);
      if (index != -1) {
        _projects[index] = updatedProject;
        notifyListeners();
      }
    } catch (e) {
      throw Exception('軸設定の更新に失敗しました: $e');
    }
  }

  /// プロジェクトを更新（現在はローカルリストのみ更新）
  void updateProject(ProjectModel updatedProject) {
    final index = _projects.indexWhere((p) => p.storageRef == updatedProject.storageRef);
    if (index != -1) {
      _projects[index] = updatedProject;
      notifyListeners();
    }
  }

  /// プロジェクトを削除（Cloud Storageからも削除）
  Future<void> deleteProject(String storageRef) async {
    try {
      // CSVファイルを削除
      await _storageService.deleteFile(storageRef);
      
      // 軸設定ファイルも削除
      final fileName = storageRef.split('/').last;
      final configPath = _storageService.getAxisConfigPath(fileName);
      try {
        await _storageService.deleteFile(configPath);
      } catch (e) {
        // 軸設定ファイルが存在しない場合は無視
        print('軸設定ファイルの削除に失敗（ファイルが存在しない可能性）: $e');
      }
      
      _projects.removeWhere((project) => project.storageRef == storageRef);
      notifyListeners();
    } catch (e) {
      throw Exception('プロジェクトの削除に失敗しました: $e');
    }
  }
}