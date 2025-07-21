# Firebase Cloud Storage統合実装計画

## プロジェクト概要
Scatter3D CommunityアプリケーションにFirebase Cloud Storage統合を実装し、現在のローカルSembastデータベースからクラウドベースのCSVファイル管理システムに移行します。

## 実装要件
1. Cloud StorageからCSVファイル一覧を読み取ってFlutterアプリ上にリスト形式で表示
2. リストで選択されたアイテムをダウンロードして3Dで表示
3. ユーザーのCSVファイル保存時にCloud Storageへアップロード
4. .envファイルを使用したFirebaseアクセス情報の管理

## 必要なFirebaseコンソール操作

### Firebase Console側で実施が必要な作業（重要）
1. **Authentication（認証）の有効化**
   - Firebase Console > Authentication > Sign-in method
   - 「Anonymous」を有効化（Enable）する
   - これを行わないとアプリ起動時にエラーが発生します

2. **Cloud Storageの有効化**
   - Firebase Console > Storage > Get started
   - デフォルトバケットの作成
   - リージョンを選択（asia-northeast1推奨）

3. **ストレージセキュリティルールの設定**
   ```javascript
   // 開発用（本番環境では認証を実装）
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /{allPaths=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```
   ※匿名認証ユーザーのみアクセス可能にする設定

## 技術アーキテクチャ

### 依存関係
- `firebase_storage: ^12.3.1` - Cloud Storage操作
- `flutter_dotenv: ^5.1.0` - 環境変数管理

### ディレクトリ構造変更
```
lib/
├── services/
│   └── firebase_storage_service.dart  # 新規：Cloud Storage操作
├── pages/
│   └── cloud_files_page.dart         # 新規：ファイル一覧表示
├── projects/
│   ├── project_model.dart            # 修正：Storage URL対応
│   ├── project_dao.dart              # 修正：Cloud Storage対応
│   └── project_provider.dart         # 修正：非同期処理対応
└── pages/
    └── home_page.dart                # 修正：クラウドファイル対応
```

### データフロー
1. **ファイル一覧表示**：Cloud Storage → firebase_storage_service → cloud_files_page
2. **ファイルダウンロード**：Cloud Storage → project_dao → 3D表示
3. **ファイルアップロード**：local CSV → firebase_storage_service → Cloud Storage

## 実装ステップ

### フェーズ1：基盤設定
- [x] PLAN.mdの作成
- [x] pubspec.yamlに依存関係追加
- [x] Firebase匿名認証の設定
- [x] ローカルデータベースコードの削除

### フェーズ2：サービス層実装
- [x] Firebase Storage サービスクラス実装
- [x] ProjectModelの Cloud Storage対応
- [x] ProjectProviderの完全な書き換え

### フェーズ3：UI層実装
- [x] ProjectProviderの非同期処理対応
- [x] Import CSV機能をCloud Storageアップロードに変更
- [x] 既存画面のCloud Storage対応

### フェーズ4：Firebase Console設定（必須）
- [ ] **Authentication（匿名認証）の有効化**: 最重要！これなしではアプリが起動しません
- [ ] **Cloud Storageの有効化**: Firebase Console > Storage > Get started
- [ ] **ストレージセキュリティルールの設定**: 匿名認証ユーザー用のルールを適用
- [ ] **プロジェクトの動作確認**: CSV アップロード・ダウンロード機能のテスト

## トラブルシューティング

### エラー: internal-error / auth/operation-not-allowed
**原因**: Firebase Authenticationの匿名認証が有効化されていない
**解決方法**: 
1. Firebase Console > Authentication > Sign-in method
2. 「Anonymous」を「Enable」に変更
3. アプリを再起動

### エラー: Firebase Storage access denied
**原因**: Storageのセキュリティルールが設定されていない
**解決方法**:
1. Firebase Console > Storage > Rules
2. 上記のセキュリティルールをコピー&ペースト
3. 「Publish」をクリック

## ファイル変更概要

### 新規作成ファイル
- `PLAN.md` - この実装計画書
- `.env` - Firebase設定情報
- `lib/services/firebase_storage_service.dart` - Cloud Storage操作サービス
- `lib/pages/cloud_files_page.dart` - ファイル一覧表示画面

### 修正対象ファイル
- `pubspec.yaml` - 依存関係追加
- `.gitignore` - .env除外設定
- `lib/projects/project_model.dart` - Storage URL対応
- `lib/projects/project_dao.dart` - Cloud Storage操作に置き換え
- `lib/projects/project_provider.dart` - 非同期処理対応
- `lib/pages/home_page.dart` - クラウドファイル選択機能追加

## セキュリティ考慮事項
- 本実装では開発用にStorage認証を無効化
- 本番環境では適切な認証・認可の実装が必要
- .envファイルの機密情報管理

### 認証実装計画
1. **初期実装**：匿名認証（Firebase Anonymous Auth）を使用
   - サービスアカウントキーの管理問題を回避
   - Gitリポジトリに機密情報を含める必要がない
   - 開発・テストが容易

2. **将来の実装**：Firebase Authenticationへの移行
   - Google認証、メール/パスワード認証などの実装
   - ユーザー別のファイル管理
   - より細かいアクセス制御

## パフォーマンス考慮事項
- ファイルダウンロードの進捗表示
- 大容量CSVファイルの分割アップロード
- キャッシュ戦略の実装

---
作成日：2025-07-21  
作成者：Claude Code  
プロジェクト：Scatter3D Community Firebase統合