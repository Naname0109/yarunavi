#!/bin/bash
# yarunavi PR 動画 (15 秒) の Simulator 録画スクリプト。
# 1. iPhone 17 Pro Max シミュレータをクリーン boot
# 2. xcrun simctl io recordVideo を background で起動
# 3. integration_test/promo_video_test.dart を flutter drive で自動再生
# 4. SIGINT で録画停止
# 5. screenshots/promo/raw_recording.mp4 に保存
#
# 録画後の編集 (字幕/フェード/BGM mix) は tool/promo_video_compose.py で行う。

set -e

PROJECT_DIR="/Users/akebi/Documents/AppFactory/yarunavi"
OUT_DIR="$PROJECT_DIR/screenshots/promo"
RAW_VIDEO="$OUT_DIR/raw_recording.mp4"
SIM="${PROMO_SIM:-iPhone 17 Pro Max}"
ENV_FILE="$PROJECT_DIR/ios/fastlane/.env.local"

mkdir -p "$OUT_DIR"
cd "$PROJECT_DIR"

echo "=========================================="
echo " YaruNavi PR Promo Video Recorder"
echo " device = $SIM"
echo " output = $RAW_VIDEO"
echo "=========================================="

# -------- 1. Simulator boot --------
echo "[1/4] Simulator boot..."
xcrun simctl shutdown all 2>/dev/null || true
xcrun simctl erase "$SIM" 2>/dev/null || true
xcrun simctl boot "$SIM"
open -a Simulator
sleep 5
xcrun simctl ui "$SIM" appearance dark
xcrun simctl status_bar "$SIM" override \
  --time "9:41" --batteryState charged --batteryLevel 100 \
  --cellularMode active --cellularBars 4
echo "  OK"

# -------- 2. recordVideo を background で起動 --------
echo "[2/4] start recordVideo (background)..."
rm -f "$RAW_VIDEO"
xcrun simctl io "$SIM" recordVideo --type=mp4 --codec=h264 "$RAW_VIDEO" &
REC_PID=$!
trap 'echo "[CLEANUP] stop recording (pid=$REC_PID)"; kill -INT $REC_PID 2>/dev/null || true' EXIT
sleep 2
echo "  recording pid=$REC_PID"

# -------- 3. flutter drive で promo シナリオを再生 --------
echo "[3/4] flutter drive (promo scenario)..."
# .env.local から AI_PROXY_URL / AI_APP_TOKEN を読み込む
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  set -a
  source "$ENV_FILE"
  set +a
fi

AI_DEFINE=""
if [ -n "${AI_PROXY_URL:-}" ]; then
  AI_DEFINE="$AI_DEFINE --dart-define=AI_PROXY_URL=$AI_PROXY_URL"
fi
if [ -n "${AI_APP_TOKEN:-}" ]; then
  AI_DEFINE="$AI_DEFINE --dart-define=AI_APP_TOKEN=$AI_APP_TOKEN"
fi
if [ -z "$AI_DEFINE" ] && [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  AI_DEFINE="--dart-define=ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY"
fi

# screenshot_driver.dart を流用 (driver はスクショ保存だけする no-op でも OK)
flutter drive \
  --no-enable-impeller \
  $AI_DEFINE \
  --driver=test_driver/screenshot_driver.dart \
  --target=integration_test/promo_video_test.dart \
  -d "$SIM"
echo "  scenario done"

# -------- 4. recordVideo 停止 --------
echo "[4/4] stop recordVideo..."
kill -INT "$REC_PID" 2>/dev/null || true
wait "$REC_PID" 2>/dev/null || true
trap - EXIT
sync
sleep 1

if [ -f "$RAW_VIDEO" ]; then
  ls -lh "$RAW_VIDEO"
  echo ""
  echo "次に編集:"
  echo "  python3 tool/promo_video_compose.py            # 無音版"
  echo "  python3 tool/promo_video_compose.py --bgm path/to/bgm.mp3"
else
  echo "ERROR: $RAW_VIDEO が生成されていません"
  exit 1
fi
