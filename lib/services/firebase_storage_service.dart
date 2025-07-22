import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:scatter3d_community/projects/axis_config_model.dart';

class FirebaseStorageService {
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 匿名認証でサインイン
  Future<User?> signInAnonymously() async {
    try {
      // 既にサインイン済みの場合はそのまま返す
      if (_auth.currentUser != null) {
        return _auth.currentUser;
      }
      
      final UserCredential userCredential = await _auth.signInAnonymously();
      print('匿名認証成功: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      print('匿名認証エラーの詳細: $e');
      // Firebase Authenticationが有効化されていない場合の対処
      if (e.toString().contains('internal-error') || 
          e.toString().contains('auth/operation-not-allowed')) {
        throw Exception('Firebase Authentication（匿名認証）が有効化されていません。Firebase Consoleで設定してください。');
      }
      throw Exception('匿名認証に失敗しました: $e');
    }
  }

  /// CSVファイルをCloud Storageにアップロード
  Future<String> uploadCSVFile(File file, String fileName) async {
    try {
      // 匿名認証を確認
      if (_auth.currentUser == null) {
        await signInAnonymously();
      }

      // アップロード先のパスを設定（ユーザーID/csv/ファイル名）
      final String userId = _auth.currentUser!.uid;
      final String filePath = 'users/$userId/csv/$fileName';
      
      // ファイルをアップロード
      final Reference ref = _storage.ref().child(filePath);
      final UploadTask uploadTask = ref.putFile(file);
      
      // アップロード完了を待機
      final TaskSnapshot snapshot = await uploadTask;
      
      // ダウンロードURLを取得
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('ファイルのアップロードに失敗しました: $e');
    }
  }

  /// ユーザーのCSVファイル一覧を取得
  Future<List<Reference>> listCSVFiles() async {
    try {
      // 匿名認証を確認
      if (_auth.currentUser == null) {
        await signInAnonymously();
      }

      final String userId = _auth.currentUser!.uid;
      final String folderPath = 'users/$userId/csv';
      
      final Reference ref = _storage.ref().child(folderPath);
      final ListResult result = await ref.listAll();
      
      return result.items;
    } catch (e) {
      throw Exception('ファイル一覧の取得に失敗しました: $e');
    }
  }

  /// ファイルをダウンロード（バイト配列として）
  Future<List<int>> downloadFile(String filePath) async {
    try {
      final Reference ref = _storage.ref().child(filePath);
      final List<int> data = await ref.getData() ?? [];
      return data;
    } catch (e) {
      throw Exception('ファイルのダウンロードに失敗しました: $e');
    }
  }

  /// ファイルを削除
  Future<void> deleteFile(String filePath) async {
    try {
      final Reference ref = _storage.ref().child(filePath);
      await ref.delete();
    } catch (e) {
      throw Exception('ファイルの削除に失敗しました: $e');
    }
  }

  /// 現在の認証状態を確認
  bool get isSignedIn => _auth.currentUser != null;

  /// 現在のユーザーIDを取得
  String? get currentUserId => _auth.currentUser?.uid;

  /// 軸設定ファイルをCloud Storageにアップロード
  Future<String> uploadAxisConfigFile(ProjectAxisConfig config, String baseFileName) async {
    try {
      // 匿名認証を確認
      if (_auth.currentUser == null) {
        await signInAnonymously();
      }

      final String userId = _auth.currentUser!.uid;
      final String fileName = '$baseFileName.json';
      final String filePath = 'users/$userId/configs/$fileName';
      
      // JSONデータを準備
      final String jsonString = jsonEncode(config.toMap());
      final List<int> data = utf8.encode(jsonString);
      
      // ファイルをアップロード
      final Reference ref = _storage.ref().child(filePath);
      final UploadTask uploadTask = ref.putData(Uint8List.fromList(data), 
        SettableMetadata(contentType: 'application/json'));
      
      // アップロード完了を待機
      await uploadTask;
      
      return filePath;
    } catch (e) {
      throw Exception('軸設定ファイルのアップロードに失敗しました: $e');
    }
  }

  /// 軸設定ファイルをCloud Storageからダウンロード
  Future<ProjectAxisConfig?> downloadAxisConfigFile(String configPath) async {
    try {
      final Reference ref = _storage.ref().child(configPath);
      final List<int> data = await ref.getData() ?? [];
      
      if (data.isEmpty) {
        return null;
      }
      
      final String jsonString = utf8.decode(data);
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      
      return ProjectAxisConfig.fromMap(jsonMap);
    } catch (e) {
      print('軸設定ファイルのダウンロードエラー: $e');
      return null;
    }
  }

  /// ユーザーの軸設定ファイル一覧を取得
  Future<List<Reference>> listAxisConfigFiles() async {
    try {
      // 匿名認証を確認
      if (_auth.currentUser == null) {
        await signInAnonymously();
      }

      final String userId = _auth.currentUser!.uid;
      final String folderPath = 'users/$userId/configs';
      
      final Reference ref = _storage.ref().child(folderPath);
      final ListResult result = await ref.listAll();
      
      return result.items;
    } catch (e) {
      print('軸設定ファイル一覧の取得エラー: $e');
      return [];
    }
  }

  /// CSVファイル名から軸設定ファイルのパスを生成
  String getAxisConfigPath(String csvFileName) {
    final String userId = _auth.currentUser?.uid ?? '';
    final String configFileName = csvFileName.replaceAll('.csv', '.json');
    return 'users/$userId/configs/$configFileName';
  }
}