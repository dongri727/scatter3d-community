import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
}