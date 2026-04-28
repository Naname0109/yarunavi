#!/bin/bash
set -eo pipefail
cd /Users/akebi/Documents/AppFactory/yarunavi

BUNDLE_ID="com.naname0109.yarunavi"

echo "=== YaruNavi E2E Test Suite ==="
echo ""

rm -f test_results.log

# シミュレータ起動
DEVICE="iPhone 17 Pro Max"
echo "Starting simulator: $DEVICE"
xcrun simctl boot "$DEVICE" 2>/dev/null || true
open -a Simulator
echo "Waiting for simulator to boot..."
xcrun simctl bootstatus "$DEVICE" -b 2>/dev/null || sleep 5

# システム権限を事前に付与（ダイアログ表示を防止）
echo "Granting permissions..."
xcrun simctl privacy "$DEVICE" grant calendar "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl privacy "$DEVICE" grant calendar-full-access "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl privacy "$DEVICE" grant contacts "$BUNDLE_ID" 2>/dev/null || true

# E2Eテスト実行
echo "Running E2E tests..."
echo ""
flutter test integration_test/e2e_test.dart \
  -d "$DEVICE" \
  --dart-define=ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-""}" \
  --dart-define=E2E_TEST=true \
  2>&1 | tee test_results.log

echo ""
echo "=== テスト結果 ==="
grep -E "\[E2E\] (✓|✗|合計|PASS|FAIL|テスト結果)" test_results.log || true
