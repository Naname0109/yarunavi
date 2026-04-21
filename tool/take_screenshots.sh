#!/bin/bash
set -e

PROJECT_DIR="/Users/akebi/Documents/AppFactory/yarunavi"
RAW_DIR="$PROJECT_DIR/screenshots/raw"
IPAD_DIR="$PROJECT_DIR/screenshots/ipad"
FINAL_IPHONE="$PROJECT_DIR/ios/fastlane/screenshots/ja/iPhone 6.5-inch"
FINAL_IPAD="$PROJECT_DIR/ios/fastlane/screenshots/ja/iPad Pro 12.9-inch"
IPHONE_SIM="iPhone 17 Pro Max"
IPAD_SIM="iPad Air 13-inch (M3)"

mkdir -p "$RAW_DIR" "$IPAD_DIR" "$FINAL_IPHONE" "$FINAL_IPAD"

cd "$PROJECT_DIR"

echo "=========================================="
echo " YaruNavi 全自動スクリーンショット撮影"
echo "=========================================="

# ===========================================
# Phase 1: iPhone
# ===========================================
echo ""
echo "=== Phase 1: $IPHONE_SIM ==="

xcrun simctl shutdown all 2>/dev/null || true
xcrun simctl erase "$IPHONE_SIM" 2>/dev/null || true
xcrun simctl boot "$IPHONE_SIM"
open -a Simulator
sleep 5
xcrun simctl status_bar "$IPHONE_SIM" override \
  --time "9:41" --batteryState charged --batteryLevel 100 \
  --cellularMode active --cellularBars 4

# Impeller無効化: takeScreenshot()がImpellerで空画像を返す問題の回避
flutter drive \
  --no-enable-impeller \
  --driver=test_driver/screenshot_driver.dart \
  --target=integration_test/screenshot_test.dart \
  -d "$IPHONE_SIM"

echo ""
echo "iPhone raw スクショ:"
ls -la "$RAW_DIR"

# ===========================================
# Phase 2: iPad
# ===========================================
echo ""
echo "=== Phase 2: $IPAD_SIM ==="

xcrun simctl shutdown "$IPHONE_SIM" 2>/dev/null || true
xcrun simctl erase "$IPAD_SIM" 2>/dev/null || true
xcrun simctl boot "$IPAD_SIM"
open -a Simulator
sleep 5
xcrun simctl status_bar "$IPAD_SIM" override \
  --time "9:41" --batteryState charged --batteryLevel 100

flutter drive \
  --no-enable-impeller \
  --driver=test_driver/screenshot_driver_ipad.dart \
  --target=integration_test/screenshot_test.dart \
  -d "$IPAD_SIM"

echo ""
echo "iPad スクショ:"
ls -la "$IPAD_DIR"

# iPad用スクショを Fastlane フォルダにコピー
cp "$IPAD_DIR"/ipad_01_home.png "$FINAL_IPAD/" 2>/dev/null || true
cp "$IPAD_DIR"/ipad_02_ai_result.png "$FINAL_IPAD/" 2>/dev/null || true
cp "$IPAD_DIR"/ipad_03_calendar.png "$FINAL_IPAD/" 2>/dev/null || true
cp "$IPAD_DIR"/ipad_04_ai_comment.png "$FINAL_IPAD/" 2>/dev/null || true
cp "$IPAD_DIR"/ipad_iap.png "$FINAL_IPAD/ipad_05_store.png" 2>/dev/null || true

# ===========================================
# Phase 3: テキストオーバーレイ加工
# ===========================================
echo ""
echo "=== Phase 3: テキストオーバーレイ加工 ==="
python3 "$PROJECT_DIR/tool/overlay_screenshots.py"

echo ""
echo "=========================================="
echo " 全自動撮影・加工完了"
echo "=========================================="
echo "iPhone: $FINAL_IPHONE"
echo "iPad:   $FINAL_IPAD"
