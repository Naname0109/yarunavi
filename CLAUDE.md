# CLAUDE.md - YaruNavi プロジェクト設定

## プロジェクト概要
- アプリ名: YaruNavi（ヤルナビ）
- 種別: AIタスク優先順位整理アプリ（Flutter）
- 仕様書: docs/YaruNavi_Spec_v1.0.md
- 開発者: Masahiro Akebi (Naname0109)

## 技術スタック
- Flutter 3.38+ / Dart
- Riverpod（状態管理）
- go_router（ルーティング）
- sqflite（ローカルDB）
- SharedPreferences（設定保存）
- freezed + json_serializable（データモデル）
- google_mobile_ads（AdMob）
- in_app_purchase（課金）
- flutter_local_notifications（通知）
- url_launcher（外部URL）
- intl + flutter_localizations（i18n）
- device_calendar（カレンダー書き出し）
- http（Anthropic API通信）

## i18n設定
- デフォルト言語: 日本語
- arb-dir: lib/l10n
- template-arb-file: app_ja.arb
- 新しいテキストを追加したら必ず app_ja.arb と app_en.arb の両方を更新
- `flutter gen-l10n` を実行

## コーディングルール
- 1機能ずつ実装 → flutter analyze → エラー0件確認 → peer レビュー
- Freezedモデル変更後は `dart run build_runner build --delete-conflicting-outputs` を実行
- kDebugMode時はFeatureGate全解放、リリースビルドで制限
- AdMobはkDebugMode時にテストID、リリース時に本番ID
- テキストのコントラスト比はWCAG AA基準 4.5:1以上
- ResponsiveWrapper（maxWidth: 700px）を全画面に適用
- 利用規約リンクは url_launcher + LaunchMode.externalApplication + 下線付き青テキスト

## ファイル構成
```
lib/
├── main.dart
├── app.dart
├── l10n/           # arb files
├── models/         # Freezed models
├── services/       # DB, AI, notification, calendar, purchase, ad
├── providers/      # Riverpod providers
├── screens/        # 画面
├── widgets/        # 共通ウィジェット
├── utils/          # constants, ad_helper, date_utils, feature_gate
└── theme/          # app_theme, colors, text_styles
```

## 実装順序
1. プロジェクト作成 + 基本構成（Riverpod, go_router, テーマ, i18n）
2. データモデル + DB（sqflite, マイグレーション, デフォルトカテゴリ）
3. ホーム画面（タスク一覧、フィルター、完了/削除）
4. タスク追加/編集シート（バリデーション、カテゴリ選択）
5. 定期タスク（繰り返し設定、次回自動生成）
6. AI整理機能（Anthropic API連携、結果画面）
7. 通知実装（flutter_local_notifications）
8. カレンダー書き出し（device_calendar）
9. 広告実装（AdMob バナー + リワード）
10. IAP実装（サブスク + FeatureGate）
11. ストア画面（課金UI、審査要件準拠）
12. オンボーディング + スプラッシュ
13. 設定画面（言語、テーマ、データ管理）
14. UI仕上げ（テーマ調整、アニメーション、iPad対応）
15. テスト + バグ修正

## API設定

### 開発時（直接API呼び出し）
```bash
flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-xxxxx
```

### 本番（プロキシ経由）
```bash
flutter run --dart-define=AI_PROXY_URL=https://xxx.workers.dev --dart-define=AI_APP_TOKEN=xxx
```

### リリースビルド
Fastlaneの.env.localにAI_PROXY_URLとAI_APP_TOKENを設定
```bash
bundle exec fastlane release
```

### プロキシサーバー
- `proxy/` フォルダにCloudflare Workerのコード
- APIキーはCloudflare Workerの環境変数にのみ保存
- アプリにはAPIキーを一切埋め込まない
- デプロイ: `cd proxy && npx wrangler deploy`

## 重要な注意事項
- Product IDは一度使うと再利用不可（削除しても）
- IAPの「審査へ提出」ボタンは初回リリース時は絶対に押さない
- App Store説明文末尾に利用規約・プライバシーポリシーURLを必ず記載
- サブスクのローカリゼーションは日本語+英語の両方が必要
- iPadで審査されるのでResponsiveWrapper必須
- 薄い色のテキストは使わない（コントラスト比注意）
