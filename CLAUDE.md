# CLAUDE.md

このファイルは、このリポジトリでコードを扱う際にClaude Code (claude.ai/code) に対するガイダンスを提供します。

## 重要な指示

**基本的にすべての受け答えは日本語で行ってください。** ユーザーが英語での対応を明示的に求めた場合のみ英語で応答してください。

## プロジェクト概要

これは**Scatter3D Community**と呼ばれるFlutterアプリケーションで、ユーザーがCSVデータから3D散布図を作成・共有できるアプリです。データ永続化のためのFirebase統合と、プロジェクト管理のためのローカルSembastデータベースを使用しています。

## 開発コマンド

### Flutterコマンド
- `flutter run` - 接続されたデバイス/エミュレータでアプリを実行
- `flutter build android` - Android APKをビルド
- `flutter build ios` - iOSアプリをビルド
- `flutter test` - ユニットテストを実行
- `flutter analyze` - 静的解析を実行
- `flutter clean` - ビルド成果物をクリーンアップ

### 一般的な開発タスク
- `flutter pub get` - 依存関係をインストール
- `flutter pub upgrade` - 依存関係をアップグレード
- `flutter doctor` - Flutter開発環境のセットアップをチェック

## コードアーキテクチャ

### コア構造
アプリケーションは以下の主要コンポーネントを持つ標準的なFlutterアーキテクチャに従っています：

#### 状態管理
- **Provider**パターンを状態管理に使用
- メインプロバイダー：`ProjectProvider`がプロジェクトのCRUD操作を処理
- ページ固有のモデル：`HomePageModel`がホームページの状態を管理

#### データレイヤー
- **Sembastデータベース**：プロジェクト保存用のローカルNoSQLデータベース（`lib/projects/sembast_database.dart`）
- **Firebase**：`firebase.json`で設定されたクラウドバックエンド統合
- **プロジェクトデータアクセス**：`ProjectDao`がプロジェクトのデータベース操作を処理

#### UI構造
- **ページ**：`lib/pages/`のメイン画面
  - `TopPage`：ランディング/ウェルカムページ
  - `MyHomePage`：メイン設定とCSVインポート
  - `SecondPage`：散布図の可視化
  - `PreviewPage`：プロットプレビュー機能
- **ユーティリティ**：`lib/utils/`の再利用可能なウィジェットとユーティリティ
  - `AxisConfigWidget`：3D軸パラメータの設定
  - `ScatterPlotWidget`：3D散布図のレンダリング
  - `SnackBars`：カスタム通知システム

#### 主要機能
- **CSVインポート**：`CsvImporter`クラスがCSVファイルの解析と検証を処理
- **3D可視化**：3D散布図レンダリングに`flutter_echarts`を使用
- **プロジェクト管理**：プロット設定の保存/読み込みの完全なCRUD操作
- **クロスプラットフォーム**：Android、iOS、macOS、Windows、Linux、Webをサポート

### データフロー
1. ユーザーが`MyHomePage`でプロットパラメータを設定
2. CSVデータが`CsvImporter`によってインポートされ解析される
3. データが`ProjectProvider`を通じて処理され保存される
4. 3D可視化が`SecondPage`でEChartsを使用してレンダリングされる
5. プロジェクトがSembastデータベースを使用してローカルに永続化される

### 依存関係
- `flutter_echarts: ^2.5.0` - 3Dチャートレンダリング
- `provider: ^6.0.5` - 状態管理
- `sembast: ^3.5.0` - ローカルデータベース
- `firebase_core: ^3.15.1` - Firebase統合
- `file_picker: ^8.1.2` - ファイル選択
- `csv: 6.0.0` - CSV解析

## 重要な実装ノート

### Firebase設定
- Firebaseは`main.dart`でプラットフォーム固有の設定で初期化される
- 設定ファイルは自動生成されるため手動編集しない
- プロジェクトID：`db-c4a09`

### データベーススキーマ
プロジェクトは以下の構造で保存される：
- `title`：String - プロジェクト名
- `xLegend`, `yLegend`, `zLegend`：String - 軸ラベル
- `xMin`, `xMax`, `yMin`, `yMax`, `zMin`, `zMax`：double - 軸範囲
- `csvData`：List - 生のCSVデータ
- `scatterData`：List - 処理された散布図データ

### エラーハンドリング
- ユーザーフィードバック用のカスタム`SnackBar`ユーティリティを使用
- コードベース全体で日本語エラーメッセージ
- リアルタイムフィードバック付きフォーム検証

### プラットフォームサポート
- プラットフォーム固有設定を持つマルチプラットフォームFlutterアプリ
- iOS/macOSは依存関係管理にCocoaPodsを使用
- AndroidはGradleビルドシステムを使用
- faviconとmanifest付きWebサポート