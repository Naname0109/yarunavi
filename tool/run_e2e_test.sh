#!/bin/bash
set -eo pipefail
cd /Users/akebi/Documents/AppFactory/yarunavi

echo "=== YaruNavi E2E Test Suite ==="
echo ""

rm -f test_results.log

# シミュレータ起動
DEVICE="iPhone 16 Pro Max"
echo "Starting simulator: $DEVICE"
xcrun simctl boot "$DEVICE" 2>/dev/null || true
open -a Simulator
echo "Waiting for simulator to boot..."
xcrun simctl bootstatus "$DEVICE" -b 2>/dev/null || sleep 5

# E2Eテスト実行
echo "Running E2E tests..."
echo ""
flutter test integration_test/e2e_test.dart \
  -d "$DEVICE" \
  --dart-define=ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-""}" \
  2>&1 | tee test_results.log

echo ""
echo "=== テスト結果 ==="
grep -E "\[E2E\] (✓|✗|合計|PASS|FAIL|テスト結果)" test_results.log || true
