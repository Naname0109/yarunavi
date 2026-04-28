#!/bin/bash
set -e

PROJECT_DIR="/Users/akebi/Documents/AppFactory/yarunavi"
RAW_DIR="$PROJECT_DIR/screenshots/raw"
IPAD_DIR="$PROJECT_DIR/screenshots/ipad"
FINAL_IPHONE="$PROJECT_DIR/ios/fastlane/screenshots/ja/iPhone 6.7-inch"
FINAL_IPAD="$PROJECT_DIR/ios/fastlane/screenshots/ja/iPad Pro 12.9-inch"
IPHONE_SIM="iPhone 17 Pro Max"
IPAD_SIM="iPad Pro 13-inch (M5)"

mkdir -p "$RAW_DIR" "$IPAD_DIR" "$FINAL_IPHONE" "$FINAL_IPAD"

cd "$PROJECT_DIR"

echo "=========================================="
echo " YaruNavi App Store Screenshot Pipeline"
echo "=========================================="

# ===========================================
# Phase 1: iPhone (6.7-inch, 1290x2796)
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

flutter drive \
  --no-enable-impeller \
  --driver=test_driver/screenshot_driver.dart \
  --target=integration_test/screenshot_test.dart \
  -d "$IPHONE_SIM"

echo ""
echo "iPhone raw:"
ls -la "$RAW_DIR"

# ===========================================
# Phase 2: iPad (12.9-inch, 2048x2732)
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
echo "iPad raw:"
ls -la "$IPAD_DIR"

# ===========================================
# Phase 3: Marketing overlay
# ===========================================
echo ""
echo "=== Phase 3: Overlay ==="
python3 "$PROJECT_DIR/tool/overlay_screenshots.py"

echo ""
echo "=========================================="
echo " Complete"
echo "=========================================="
echo "iPhone: $FINAL_IPHONE"
echo "iPad:   $FINAL_IPAD"
