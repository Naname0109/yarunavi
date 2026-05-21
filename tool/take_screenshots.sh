#!/bin/bash
set -e

PROJECT_DIR="/Users/akebi/Documents/AppFactory/yarunavi"
# screenshot_driver は raw/ ipad/ 固定で書く。 撮影後に light/dark dir に move する。
RAW_DIR="$PROJECT_DIR/screenshots/raw"
IPAD_DIR="$PROJECT_DIR/screenshots/ipad"
RAW_LIGHT_DIR="$PROJECT_DIR/screenshots/raw_light"
IPAD_LIGHT_DIR="$PROJECT_DIR/screenshots/ipad_light"
RAW_DARK_DIR="$PROJECT_DIR/screenshots/raw_dark"
IPAD_DARK_DIR="$PROJECT_DIR/screenshots/ipad_dark"
FINAL_IPHONE="$PROJECT_DIR/ios/fastlane/screenshots/ja/iPhone 6.7-inch"
FINAL_IPAD="$PROJECT_DIR/ios/fastlane/screenshots/ja/iPad Pro 12.9-inch"
IPHONE_SIM="iPhone 17 Pro Max"
IPAD_SIM="iPad Pro 13-inch (M5)"

# 引数: --light-only / --dark-only / (default = both)
MODE="${1:-both}"

mkdir -p "$RAW_DIR" "$IPAD_DIR" \
         "$RAW_LIGHT_DIR" "$IPAD_LIGHT_DIR" \
         "$RAW_DARK_DIR" "$IPAD_DARK_DIR" \
         "$FINAL_IPHONE" "$FINAL_IPAD"

cd "$PROJECT_DIR"

echo "=========================================="
echo " YaruNavi App Store Screenshot Pipeline"
echo " mode = $MODE"
echo "=========================================="

run_iphone() {
  local theme="$1"   # light | dark
  local out_dir="$2"
  echo ""
  echo "=== iPhone [$theme] ==="
  xcrun simctl shutdown all 2>/dev/null || true
  xcrun simctl erase "$IPHONE_SIM" 2>/dev/null || true
  xcrun simctl boot "$IPHONE_SIM"
  open -a Simulator
  sleep 5
  # OS appearance 切り替え (アプリの themeMode=system → darkTheme 自動適用)
  xcrun simctl ui "$IPHONE_SIM" appearance "$theme"
  xcrun simctl status_bar "$IPHONE_SIM" override \
    --time "9:41" --batteryState charged --batteryLevel 100 \
    --cellularMode active --cellularBars 4

  local define=""
  if [ "$theme" = "dark" ]; then
    define="--dart-define=THEME_MODE=dark"
  fi

  flutter drive \
    --no-enable-impeller \
    $define \
    --driver=test_driver/screenshot_driver.dart \
    --target=integration_test/screenshot_test.dart \
    -d "$IPHONE_SIM"

  # 撮影完了したら raw 出力を退避 (light/dark を必ず分離する)
  rm -f "$out_dir"/*.png 2>/dev/null || true
  cp "$RAW_DIR"/*.png "$out_dir/"
  echo "iPhone $theme raw -> $out_dir"
  ls -la "$out_dir"
}

run_ipad() {
  local theme="$1"
  local out_dir="$2"
  echo ""
  echo "=== iPad [$theme] ==="
  xcrun simctl shutdown "$IPHONE_SIM" 2>/dev/null || true
  xcrun simctl erase "$IPAD_SIM" 2>/dev/null || true
  xcrun simctl boot "$IPAD_SIM"
  open -a Simulator
  sleep 5
  xcrun simctl ui "$IPAD_SIM" appearance "$theme"
  xcrun simctl status_bar "$IPAD_SIM" override \
    --time "9:41" --batteryState charged --batteryLevel 100

  local define=""
  if [ "$theme" = "dark" ]; then
    define="--dart-define=THEME_MODE=dark"
  fi

  flutter drive \
    --no-enable-impeller \
    $define \
    --driver=test_driver/screenshot_driver_ipad.dart \
    --target=integration_test/screenshot_test.dart \
    -d "$IPAD_SIM"

  rm -f "$out_dir"/*.png 2>/dev/null || true
  cp "$IPAD_DIR"/*.png "$out_dir/"
  echo "iPad $theme raw -> $out_dir"
  ls -la "$out_dir"
}

if [ "$MODE" = "light" ] || [ "$MODE" = "light-only" ] || [ "$MODE" = "both" ]; then
  run_iphone "light" "$RAW_LIGHT_DIR"
  run_ipad   "light" "$IPAD_LIGHT_DIR"
fi

if [ "$MODE" = "dark" ] || [ "$MODE" = "dark-only" ] || [ "$MODE" = "both" ]; then
  run_iphone "dark" "$RAW_DARK_DIR"
  run_ipad   "dark" "$IPAD_DARK_DIR"
fi

# ===========================================
# Overlay (v2: Claude Design ASO frames; dark raw を優先入力)
# ===========================================
echo ""
echo "=== Overlay (v2) ==="
if [ -f "$RAW_DARK_DIR/raw_01_home.png" ]; then
  python3 "$PROJECT_DIR/tool/overlay_screenshots_v2.py"
elif [ -f "$RAW_LIGHT_DIR/raw_01_home.png" ]; then
  python3 "$PROJECT_DIR/tool/overlay_screenshots_v2.py" --light
else
  echo "  WARN: no raw screenshots found, skip overlay"
fi

# 6.7 -> 6.5 resize (ja, en-US 両方)
echo ""
echo "=== Resize 6.7 -> 6.5 ==="
python3 "$PROJECT_DIR/tool/resize_screenshots.py"

echo ""
echo "=========================================="
echo " Complete"
echo "=========================================="
echo "iPhone: $FINAL_IPHONE"
echo "iPad:   $FINAL_IPAD"
