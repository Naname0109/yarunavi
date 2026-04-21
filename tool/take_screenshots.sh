#!/bin/bash
set -e

SAVE_DIR="/Users/akebi/Documents/AppFactory/yarunavi/screenshots/raw"
IPAD_DIR="/Users/akebi/Documents/AppFactory/yarunavi/screenshots/ipad"
mkdir -p "$SAVE_DIR" "$IPAD_DIR"

echo "=========================================="
echo " YaruNavi App Store スクリーンショット撮影"
echo "=========================================="
echo ""
echo "操作手順:"
echo "  1. 各画面を表示したら Enter を押してください"
echo "  2. 全画面撮影後、iPadに切り替えます"
echo ""

# ステータスバーを統一
xcrun simctl status_bar booted override \
  --time "9:41" \
  --batteryState charged \
  --batteryLevel 100 \
  --cellularMode active \
  --cellularBars 4

# アプリ起動
echo "[1/6] アプリを起動します..."
xcrun simctl launch booted com.naname0109.yarunavi
sleep 3

echo ""
echo "===== iPhone スクリーンショット ====="
echo ""

echo "[1/6] オンボーディング2画面目（ビフォーアフター）を表示してください"
echo "      → 「次へ」を1回タップして2画面目に進めてください"
echo "      準備ができたら Enter を押してください"
read
xcrun simctl io booted screenshot "$SAVE_DIR/raw_05_onboarding.png"
echo "  ✅ raw_05_onboarding.png 保存完了"
echo ""

echo "[2/6] ホーム画面を表示してください"
echo "      → オンボーディングを完了してホームへ"
echo "      → 設定 → 開発者モード ON → プレミアム ON → テストデータ投入"
echo "      → ホームに戻り「AIで整理」を実行"
echo "      → 整理完了後、ホームに戻ってください"
echo "      → 「今日やること」が表示された状態で Enter を押してください"
read
xcrun simctl io booted screenshot "$SAVE_DIR/raw_01_home.png"
echo "  ✅ raw_01_home.png 保存完了"
echo ""

echo "[3/6] AI整理結果画面を表示してください"
echo "      → 「AIで整理」ボタンの結果画面、または履歴から最新の結果を表示"
echo "      準備ができたら Enter を押してください"
read
xcrun simctl io booted screenshot "$SAVE_DIR/raw_02_ai_result.png"
echo "  ✅ raw_02_ai_result.png 保存完了"
echo ""

echo "[4/6] カレンダー画面を表示してください"
echo "      → ホームに戻り「カレンダー」タブを選択"
echo "      → 今週のタスクが色付きで見えている状態"
echo "      準備ができたら Enter を押してください"
read
xcrun simctl io booted screenshot "$SAVE_DIR/raw_03_calendar.png"
echo "  ✅ raw_03_calendar.png 保存完了"
echo ""

echo "[5/6] タスク展開画面（AIコメント表示）を撮影してください"
echo "      → 「やること」タブでタスクカードを1つタップ"
echo "      → AIコメントが見えている状態"
echo "      準備ができたら Enter を押してください"
read
xcrun simctl io booted screenshot "$SAVE_DIR/raw_04_ai_comment.png"
echo "  ✅ raw_04_ai_comment.png 保存完了"
echo ""

echo "[6/6] ストア画面（IAP）を表示してください"
echo "      → 設定 → プレミアムプラン のストア画面"
echo "      準備ができたら Enter を押してください"
read
xcrun simctl io booted screenshot "$SAVE_DIR/raw_iap.png"
echo "  ✅ raw_iap.png 保存完了"
echo ""

echo "===== iPhone スクリーンショット 完了 ====="
echo ""
echo "ファイル一覧:"
ls -la "$SAVE_DIR"
echo ""

echo "===== iPad に切り替えます ====="
echo ""

# iPhone シミュレータ終了
xcrun simctl shutdown "iPhone 17 Pro Max"

# iPad 起動
xcrun simctl boot "iPad Air 13-inch (M3)" 2>/dev/null || true
open -a Simulator
sleep 3

# ステータスバー
xcrun simctl status_bar booted override \
  --time "9:41" \
  --batteryState charged \
  --batteryLevel 100

# iPadにアプリインストール・起動
echo "iPadにアプリをインストール中..."
cd /Users/akebi/Documents/AppFactory/yarunavi
flutter build ios --debug --simulator 2>&1 | tail -2
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
xcrun simctl launch booted com.naname0109.yarunavi
sleep 3

echo ""
echo "===== iPad スクリーンショット ====="
echo ""
echo "※ iPhoneと同じ操作で各画面を表示してください"
echo ""

echo "[1/5] iPad: ホーム画面を表示して Enter を押してください"
read
xcrun simctl io booted screenshot "$IPAD_DIR/ipad_01_home.png"
echo "  ✅ ipad_01_home.png 保存完了"
echo ""

echo "[2/5] iPad: AI整理結果画面を表示して Enter を押してください"
read
xcrun simctl io booted screenshot "$IPAD_DIR/ipad_02_ai_result.png"
echo "  ✅ ipad_02_ai_result.png 保存完了"
echo ""

echo "[3/5] iPad: カレンダー画面を表示して Enter を押してください"
read
xcrun simctl io booted screenshot "$IPAD_DIR/ipad_03_calendar.png"
echo "  ✅ ipad_03_calendar.png 保存完了"
echo ""

echo "[4/5] iPad: タスク展開画面を表示して Enter を押してください"
read
xcrun simctl io booted screenshot "$IPAD_DIR/ipad_04_ai_comment.png"
echo "  ✅ ipad_04_ai_comment.png 保存完了"
echo ""

echo "[5/5] iPad: ストア画面を表示して Enter を押してください"
read
xcrun simctl io booted screenshot "$IPAD_DIR/ipad_05_store.png"
echo "  ✅ ipad_05_store.png 保存完了"
echo ""

echo "===== 全スクリーンショット撮影完了 ====="
echo ""
echo "iPhone スクリーンショット:"
ls -la "$SAVE_DIR"
echo ""
echo "iPad スクリーンショット:"
ls -la "$IPAD_DIR"
