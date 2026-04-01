# YaruNavi（ヤルナビ）仕様書 v1.0

## 1. アプリ概要

### コンセプト
「いつまでに、何をすればいいか」をAIが整理し、適切なタイミングで通知してくれるタスク管理アプリ。

### ワンライン
タスク名と期限を入れるだけ。AIが優先順位を整理し、やるべき日に通知してくれる。

### ターゲットユーザー
- プライベートのやることが多く、頭の中だけで管理しきれない人
- 手続き・支払い・買い物など生活タスクを忘れがちな人
- 仕事用のタスク管理ツール（Todoist, Notion等）にプライベートを混ぜたくない人
- 20-40代、スマホメインユーザー

### 対応言語
- 日本語（デフォルト）
- 英語
- 設定画面で切替可能、SharedPreferencesで永続化

### 対応プラットフォーム
- iOS（iPhone専用、iPadレスポンシブ対応）
- Android（将来：iOS審査通過後に提出）

---

## 2. 画面構成

### 画面一覧

```
[スプラッシュ] → [オンボーディング（初回のみ）] → [ホーム]
                                                      ├── [タスク追加/編集シート]
                                                      ├── [AI整理結果]
                                                      ├── [設定]
                                                      │    ├── [通知設定]
                                                      │    ├── [言語設定]
                                                      │    ├── [テーマ設定]
                                                      │    └── [データ管理]
                                                      └── [ストア（プレミアム案内）]
```

### 2-1. スプラッシュ画面
- アプリアイコン + アプリ名表示
- 1.5秒後にホームへ遷移（初回のみオンボーディングへ）
- バナー広告なし

### 2-2. オンボーディング（初回のみ・3画面）
- **画面1**: 「タスク名と期限を入れるだけ」（入力の簡単さ訴求）
- **画面2**: 「AIが優先順位を整理」（AI機能訴求）
- **画面3**: 「やるべき日に通知でお知らせ」（通知許可ダイアログ誘導）
- 「はじめる」ボタンでホームへ
- スキップ可能
- バナー広告なし

### 2-3. ホーム画面（メイン）
アプリの中心画面。タスク一覧を表示する。

#### レイアウト
- **上部**: 日付表示（今日の日付）+ フィルタータブ
- **中央**: タスクリスト
- **下部**: バナー広告（無料ユーザーのみ）
- **FAB**: 「+」ボタン（タスク追加）
- **右上**: 設定アイコン

#### フィルタータブ
- 「すべて」「今日」「今週」「期限切れ」「完了済み」
- 横スクロールで切替

#### タスクリストの表示
各タスクカードに以下を表示:
- タスク名
- 期限日（「今日」「明日」「3日後」「4/15(火)」等の相対/絶対表示）
- カテゴリアイコン（設定済みの場合）
- 定期タスクアイコン（🔄、定期タスクの場合）
- 優先度インジケーター（AI整理実行済みの場合、色で表示）
  - 赤: 緊急（期限切れ or 今日）
  - オレンジ: 要注意（1-3日以内）
  - 青: 通常
  - グレー: 余裕あり（7日以上先）
- 完了チェックボックス（左端、タップで完了）

#### タスクカードのインタラクション
- タップ: 編集シートを開く
- 左スワイプ: 削除（確認ダイアログ）
- 右スワイプ: 完了/未完了トグル
- 長押し: なし（シンプルに保つ）

### 2-4. タスク追加/編集シート（ボトムシート）
ホーム画面からFABまたはタスクタップで表示。

#### 入力フィールド
- **タスク名**（必須）: テキスト入力、1行
- **期限日**（必須）: 日付ピッカー（デフォルト: 今日から7日後）
- **メモ**（任意）: テキスト入力、複数行、折りたたみ表示
- **カテゴリ**（任意）: 選択式（後述のカテゴリ一覧から選択）
- **定期設定**（任意）: 「なし / 毎週 / 毎月 / 毎年 / カスタム」
  - カスタム: 「○日ごと」「毎月○日」「毎年○月○日」
- **通知設定**（任意）: 「期限日 / 1日前 / 3日前 / 1週間前 / カスタム」複数選択可

#### ボタン
- 「保存」: タスクを保存してシートを閉じる
- 「キャンセル」: シートを閉じる（変更破棄）

### 2-5. AI整理結果画面
AI整理を実行した後に表示される画面。

#### レイアウト
- **ヘッダー**: 「AIが整理しました」+ 整理日時
- **セクション別タスクリスト**:
  - 「🔴 今すぐやるべき」: 期限切れ + 今日期限
  - 「🟠 今週中に」: 1-7日以内
  - 「🔵 来週以降」: 8日以上先
  - 「⚪ 急がないが忘れずに」: 期限に余裕がある or 定期タスクの次回
- **各タスクにAIコメント**: 1行の簡潔な理由（例:「期限まで2日。平日の手続きなので明日中に」）
- 「ホームに戻る」ボタン

#### AI整理のトリガー
- ホーム画面の「AIで整理」ボタン（画面上部 or FABの隣）
- 無料: 月3回まで（残回数を表示）
- プレミアム: 無制限

### 2-6. 設定画面
- **アカウント**: プレミアムステータス表示
- **通知**: デフォルト通知タイミング設定
- **言語**: 日本語 / English
- **テーマ**: ライト / ダーク / 端末設定に従う
- **データ管理**: データエクスポート（CSV）、全データ削除
- **プレミアムに登録**: ストア画面へ遷移
- **利用規約**: url_launcher（外部ブラウザ）
- **プライバシーポリシー**: url_launcher（外部ブラウザ）
- **アプリ情報**: バージョン、ライセンス
- バナー広告あり（無料ユーザーのみ）

### 2-7. ストア画面（プレミアム案内）
課金画面。App Store審査要件を全て満たす設計。

#### 表示要素
- **プレミアム機能一覧**:
  - AI整理 無制限（無料は月3回）
  - タスク登録 無制限（無料は10件）
  - 定期タスク 無制限（無料は1件）
  - カテゴリ 無制限（無料は2つ）
  - カレンダー書き出し
  - 期限日の通知（無料はアプリ内のみ）
  - 広告非表示
- **価格ボタン**:
  - 月額: 「¥580/月」
  - 年額: 「¥4,200/年（¥350/月相当・40%おトク）」
  - 各ボタン下に「7日間無料 → その後 月額¥580」等の明示
- **自動更新に関する警告**（オレンジ太字14sp）:
  - 「無料体験終了後、自動的に課金されます」
  - 「いつでもキャンセル可能。無料体験中のキャンセルで課金されません」
- **「購入を復元」ボタン**
- **利用規約リンク**: 下線付き青テキスト、url_launcher + LaunchMode.externalApplication
  - https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
- **プライバシーポリシーリンク**: 同上
  - https://naname0109.github.io/yarunavi/
- バナー広告なし

---

## 3. データモデル

### 3-1. テーブル設計（sqflite）

#### tasks テーブル
```sql
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,                    -- タスク名
  due_date TEXT NOT NULL,                 -- 期限日（ISO 8601: yyyy-MM-dd）
  memo TEXT,                              -- メモ（任意）
  category_id INTEGER,                    -- カテゴリID（FK）
  is_completed INTEGER NOT NULL DEFAULT 0, -- 完了フラグ（0/1）
  completed_at TEXT,                      -- 完了日時
  priority INTEGER NOT NULL DEFAULT 0,    -- AI優先度（0:未設定, 1:緊急, 2:要注意, 3:通常, 4:余裕）
  ai_comment TEXT,                        -- AIコメント（1行）
  recurrence_type TEXT,                   -- 繰り返し種別（null/weekly/monthly/yearly/custom）
  recurrence_value INTEGER,              -- 繰り返し値（毎月の場合: 日、カスタムの場合: 日数）
  recurrence_parent_id INTEGER,          -- 定期タスクの親ID（生成元タスクのID）
  notify_settings TEXT,                   -- 通知設定JSON（例: ["on_due","1_day_before"]）
  created_at TEXT NOT NULL,               -- 作成日時
  updated_at TEXT NOT NULL                -- 更新日時
);
```

#### categories テーブル
```sql
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,                     -- カテゴリ名
  icon TEXT NOT NULL,                     -- アイコン絵文字
  sort_order INTEGER NOT NULL DEFAULT 0,  -- 表示順
  created_at TEXT NOT NULL
);
```

#### ai_usage テーブル
```sql
CREATE TABLE ai_usage (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  used_at TEXT NOT NULL,                  -- 使用日時
  month_key TEXT NOT NULL                 -- 月キー（yyyy-MM）集計用
);
```

#### app_settings テーブル（SharedPreferencesでも可）
```
- locale: String (ja / en)
- theme_mode: String (light / dark / system)
- is_premium: bool
- is_onboarding_completed: bool
- default_notify_settings: String (JSON)
- last_ai_sort_at: String (ISO 8601)
```

### 3-2. Freezedモデル

```dart
// lib/models/task.dart
@freezed
class Task with _$Task {
  const factory Task({
    int? id,
    required String title,
    required DateTime dueDate,
    String? memo,
    int? categoryId,
    @Default(false) bool isCompleted,
    DateTime? completedAt,
    @Default(0) int priority,
    String? aiComment,
    String? recurrenceType,
    int? recurrenceValue,
    int? recurrenceParentId,
    String? notifySettings,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}

// lib/models/category.dart
@freezed
class Category with _$Category {
  const factory Category({
    int? id,
    required String name,
    required String icon,
    @Default(0) int sortOrder,
    required DateTime createdAt,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
}
```

### 3-3. デフォルトカテゴリ（初期データ）
| ID | アイコン | 名前(ja) | 名前(en) |
|---|---|---|---|
| 1 | 💰 | お金・支払い | Payment |
| 2 | 📋 | 手続き・届出 | Paperwork |
| 3 | 🛒 | 買い物 | Shopping |
| 4 | 🏠 | 家事・生活 | Household |
| 5 | 💼 | 仕事 | Work |
| 6 | 🎯 | その他 | Other |

※ 無料ユーザーは2カテゴリまで使用可能（デフォルト全表示だが、タスクへの割当は2つまで）

---

## 4. 機能一覧

### 4-1. 無料 / プレミアム 機能対比

| 機能 | 無料 | プレミアム |
|---|---|---|
| タスク登録 | 10件まで | 無制限 |
| 定期タスク | 1件まで | 無制限 |
| カテゴリ使用 | 2つまで | 無制限 |
| AI優先順位整理 | 月3回 | 無制限 |
| 期限日の通知（プッシュ） | ✕ | ○ |
| カレンダー書き出し | ✕ | ○ |
| AIコメント表示 | ✕（優先度の色のみ） | ○ |
| バナー広告 | あり | なし |
| リワード広告で一時解放 | ○（1回で24h） | - |
| タスク完了・編集・削除 | ○ | ○ |
| フィルター表示 | ○ | ○ |
| テーマ切替 | ○ | ○ |
| 言語切替 | ○ | ○ |
| データエクスポート | ○ | ○ |

### 4-2. リワード広告による一時解放
- 対象: AI整理の回数制限解除（24時間）
- 表示条件: 月3回のAI整理を使い切った後、「AI整理」ボタン横に「動画を見て使う」を表示
- 2日目以降に表示（初日は非表示）
- 波きぶんで確立済みのFeatureGateパターンを踏襲

---

## 5. AI機能の詳細

### 5-1. AI整理リクエスト

#### 使用モデル
- Claude Haiku 4.5（via Anthropic API）
- Prompt Caching有効（システムプロンプトをキャッシュ）

#### システムプロンプト（キャッシュ対象）
```
あなたはタスク管理の専門家です。ユーザーのタスクリストを受け取り、
以下のルールに従って優先順位を整理してください。

## 分類ルール
- priority 1（緊急）: 期限切れ、または今日が期限
- priority 2（要注意）: 期限まで1-3日
- priority 3（通常）: 期限まで4-7日
- priority 4（余裕）: 期限まで8日以上

## 考慮事項
- 手続き・届出系は「営業日」を考慮（土日を挟む場合は前倒し）
- 支払い系は「引き落とし日の前日まで」に完了を推奨
- 買い物系は他のタスクと同日にまとめる提案可
- 定期タスクは次回発生日で判断

## 出力形式
JSON配列で返してください。各要素:
{
  "task_id": <int>,
  "priority": <1-4>,
  "comment_ja": "<日本語の1行コメント>",
  "comment_en": "<英語の1行コメント>"
}
```

#### ユーザープロンプト（毎回送信）
```
今日の日付: {today}
曜日: {dayOfWeek}

タスクリスト:
{tasks_json}
```

#### レスポンス処理
1. JSON配列をパース
2. 各タスクのpriority, ai_commentを更新（DBに保存）
3. AI整理結果画面に遷移
4. ai_usageテーブルに記録

#### エラーハンドリング
- API通信エラー: 「接続に失敗しました。ネットワークを確認してください」
- レスポンスパースエラー: 期限日ベースのフォールバック優先度を適用
- レート制限: 「しばらく時間をおいてお試しください」

### 5-2. API費用管理
- 無料ユーザー: 月3回制限（ai_usageテーブルで管理）
- プレミアムユーザー: 1日5回の上限（過度利用防止）
- システムプロンプトはPrompt Cachingで90%節約

---

## 6. 通知設計

### 6-1. 通知の種類

| 種類 | 内容 | 対象 |
|---|---|---|
| 期限通知 | 「[タスク名] の期限は [日付] です」 | プレミアムのみ |
| 期限前通知 | 「[タスク名] の期限まであと [N日] です」 | プレミアムのみ |
| 期限超過通知 | 「[タスク名] の期限が過ぎています」 | プレミアムのみ |
| 定期タスク通知 | 「[タスク名] の時期です」 | プレミアムのみ |

### 6-2. 通知タイミング
- デフォルト: 期限日の朝9:00
- ユーザーがタスクごとにカスタマイズ可能:
  - 期限当日
  - 1日前
  - 3日前
  - 1週間前
  - 複数選択可
- flutter_local_notificationsで実装

### 6-3. 通知がない日
- 期限が当日・通知日に該当するタスクがなければ通知なし
- 「やることがない日は静か」が正しい体験

### 6-4. 無料ユーザーの通知体験
- プッシュ通知なし
- アプリ内で期限切れ・期限間近のタスクを赤/オレンジで強調表示
- 「通知を受け取るにはプレミアムに登録」の導線を設定画面に配置

---

## 7. 定期タスク

### 7-1. 繰り返しパターン
| 種別 | 例 | recurrence_type | recurrence_value |
|---|---|---|---|
| 毎週 | 毎週月曜 | weekly | 1 (月曜=1) |
| 毎月 | 毎月15日 | monthly | 15 |
| 毎年 | 毎年3月15日 | yearly | 315 (月×100+日) |
| カスタム | 14日ごと | custom | 14 |

### 7-2. 次回タスクの自動生成
- 定期タスクを完了した時点で、次回分のタスクを自動生成
- 生成されるタスクは recurrence_parent_id に元タスクのIDを持つ
- 次回の due_date は繰り返しルールに基づいて計算
- 未完了のまま期限を過ぎた場合: 期限超過として表示し続ける（自動スキップしない）

---

## 8. カレンダー書き出し（プレミアム機能）

### 8-1. 実装方法
- `device_calendar` パッケージ使用
- iOS: EventKit、Android: CalendarProvider

### 8-2. 動作
- タスク保存時に「カレンダーに追加」トグル（プレミアムのみ表示）
- ONの場合、端末のデフォルトカレンダーに終日イベントとして追加
- イベント名: タスク名
- 日付: 期限日
- メモ: タスクのメモ内容
- タスク編集時にカレンダーイベントも更新
- タスク削除時にカレンダーイベントも削除

---

## 9. 収益モデル

### 9-1. サブスクリプション
| プラン | Product ID | 価格 | 備考 |
|---|---|---|---|
| 月額プレミアム | yarunavi_premium_monthly | ¥580/月 | 7日間無料トライアル |
| 年額プレミアム | yarunavi_premium_yearly | ¥4,200/年 | 7日間無料トライアル |

### 9-2. 広告
| 種別 | 配置 | 表示条件 |
|---|---|---|
| バナー広告 | ホーム、設定（画面下部） | 無料ユーザー、初日から |
| リワード動画 | AI整理回数超過時 | 無料ユーザー、2日目から |

### 9-3. 広告を表示しない画面
- ストア（課金画面）
- タスク追加/編集シート
- オンボーディング
- スプラッシュ
- AI整理結果画面

### 9-4. FeatureGate実装
```dart
bool get isPremium => _purchaseService.isPremium || kDebugMode;
```
- kDebugMode時は全機能解放（開発・テスト用）
- リリースビルドでは課金状態に基づいて制限

---

## 10. 技術スタック

### 依存パッケージ
| パッケージ | 用途 |
|---|---|
| flutter_riverpod | 状態管理 |
| go_router | ルーティング |
| sqflite | ローカルDB |
| shared_preferences | 設定保存 |
| freezed + json_serializable | データモデル |
| google_mobile_ads | AdMob広告 |
| in_app_purchase | 課金 |
| flutter_local_notifications | 通知 |
| url_launcher | 外部URL遷移 |
| intl + flutter_localizations | i18n |
| device_calendar | カレンダー書き出し |
| http | Anthropic API通信 |

### ディレクトリ構成
```
lib/
├── main.dart
├── app.dart
├── l10n/
│   ├── app_ja.arb
│   └── app_en.arb
├── models/
│   ├── task.dart
│   ├── task.freezed.dart
│   ├── task.g.dart
│   ├── category.dart
│   ├── category.freezed.dart
│   └── category.g.dart
├── services/
│   ├── database_service.dart
│   ├── ai_service.dart
│   ├── notification_service.dart
│   ├── calendar_service.dart
│   ├── purchase_service.dart
│   └── ad_service.dart
├── providers/
│   ├── task_provider.dart
│   ├── category_provider.dart
│   ├── settings_provider.dart
│   └── purchase_provider.dart
├── screens/
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── home_screen.dart
│   ├── ai_result_screen.dart
│   ├── settings_screen.dart
│   └── store_screen.dart
├── widgets/
│   ├── task_card.dart
│   ├── task_form_sheet.dart
│   ├── filter_tabs.dart
│   ├── ai_sort_button.dart
│   ├── premium_badge.dart
│   ├── banner_ad_widget.dart
│   └── responsive_wrapper.dart
├── utils/
│   ├── constants.dart
│   ├── ad_helper.dart
│   ├── date_utils.dart
│   └── feature_gate.dart
└── theme/
    ├── app_theme.dart
    ├── colors.dart
    └── text_styles.dart
```

---

## 11. デザインガイドライン

### 11-1. カラーパレット
**ライトテーマ**
- Primary: #2563EB（青、信頼・整理のイメージ）
- Secondary: #F59E0B（アンバー、アクセント）
- Background: #FAFAFA
- Surface: #FFFFFF
- Text Primary: rgba(0,0,0,0.87)（WCAG AA 4.5:1以上）
- Text Secondary: rgba(0,0,0,0.60)
- Error/緊急: #DC2626
- Warning/要注意: #F97316
- Normal: #2563EB
- 余裕: #9CA3AF

**ダークテーマ**
- Primary: #60A5FA
- Secondary: #FBBF24
- Background: #121212
- Surface: #1E1E1E
- Text Primary: #FFFFFF
- Text Secondary: rgba(255,255,255,0.70)

### 11-2. フォント
- 日本語: Noto Sans JP（システムフォント）
- 英語: Roboto（システムフォント）

### 11-3. コントラスト
- 全テキスト WCAG AA基準 4.5:1以上
- 薄いグレー（opacity 0.5以下）のテキストは使用しない

### 11-4. レスポンシブ対応
- ResponsiveWrapper: maxWidth 700px を全画面に適用
- iPad審査対応（iPad Air 11-inch M3で検証）

### 11-5. アプリアイコン
- モチーフ: チェックリスト + AI（スパークル ✨）
- ベースカラー: #2563EB（プライマリ青）
- スタイル: フラットデザイン、角丸

---

## 12. App Store申請情報

### 12-1. 基本情報
- アプリ名: YaruNavi - AIタスク整理
- サブタイトル: いつ何をやるかAIが教えてくれる
- バンドルID: com.naname0109.yarunavi
- SKU: yarunavi
- プライマリ言語: 日本語
- カテゴリ: 仕事効率化（Productivity）

### 12-2. プライバシーポリシー
- URL: https://naname0109.github.io/yarunavi/
- GitHub Pages（リポジトリ: yarunavi, docs/index.html）

### 12-3. アプリのプライバシー
- データ収集: はい（AdMobが収集）
- 収集データ: ID（デバイスID）、使用状況データ（広告データ、製品の操作、その他の使用状況）
- 各データの使用目的: サードパーティ広告
- ユーザーにリンク: いいえ
- トラッキング: いいえ
- ※ Anthropic APIへのタスクデータ送信についても記載する

### 12-4. IAP / サブスクリプション登録

#### サブスクリプショングループ: YaruNavi Premium
| 項目 | 月額プラン | 年額プラン |
|---|---|---|
| 参照名 | YaruNavi Monthly Premium | YaruNavi Yearly Premium |
| Product ID | yarunavi_premium_monthly | yarunavi_premium_yearly |
| 期間 | 1ヶ月 | 1年 |
| 価格 | ¥580 | ¥4,200 |
| お試しオファー | 無料7日間 | 無料7日間 |
| ローカリゼーション | 日本語 + 英語 | 日本語 + 英語 |
| 審査用スクショ | ストア画面 | ストア画面 |
| 審査メモ | 英語で記載 | 英語で記載 |

**※「審査へ提出」ボタンは絶対に押さない。ステータスを「審査準備完了」のまま維持する。**

### 12-5. 説明文末尾
```
利用規約: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
プライバシーポリシー: https://naname0109.github.io/yarunavi/
```

### 12-6. キーワード（100文字以内）
```
タスク,AI,優先順位,やること,リマインダー,定期,支払い,手続き,通知,管理
```

---

## 13. 実装順序

| ステップ | 内容 | 目安 |
|---|---|---|
| 1 | プロジェクト作成 + 基本構成（Riverpod, go_router, テーマ, i18n） | 0.5日 |
| 2 | データモデル + DB（sqflite, マイグレーション, デフォルトカテゴリ） | 0.5日 |
| 3 | ホーム画面（タスク一覧表示, フィルター, 完了/削除） | 1日 |
| 4 | タスク追加/編集シート（バリデーション, カテゴリ選択） | 0.5日 |
| 5 | 定期タスク（繰り返し設定, 次回自動生成） | 0.5日 |
| 6 | AI整理機能（Anthropic API連携, 結果画面） | 1日 |
| 7 | 通知実装（flutter_local_notifications, 期限ベース） | 0.5日 |
| 8 | カレンダー書き出し（device_calendar） | 0.5日 |
| 9 | 広告実装（AdMob バナー + リワード） | 0.5日 |
| 10 | IAP実装（サブスク + FeatureGate） | 1日 |
| 11 | ストア画面（課金UI, 審査要件準拠） | 0.5日 |
| 12 | オンボーディング + スプラッシュ | 0.5日 |
| 13 | 設定画面（言語, テーマ, データ管理） | 0.5日 |
| 14 | UI仕上げ（テーマ調整, アニメーション, iPad対応） | 1日 |
| 15 | テスト + バグ修正 | 1日 |
| **合計** | | **約10日** |

---

## 14. 将来の拡張（v1.1以降）

- Google Calendar双方向同期（読み込み→AIが空き時間を考慮）
- ウィジェット（ホーム画面にタスク表示）
- タスク共有（URL or QRコードで他ユーザーに送信）
- AI自然言語入力（「来週の金曜までに確定申告」でタスク自動生成）
- 統計画面（完了率、カテゴリ別集計）
- Apple Watch対応
