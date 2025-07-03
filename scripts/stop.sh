#!/bin/bash
# スクリプトの実行ディレクトリに移動
cd "$(dirname "$0")" || exit

# app.pidのパスを修正
PID_FILE="../app.pid" # ルートディレクトリに配置

if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  echo "Stopping WayaGetSystemData (PID: $PID)..."
  if kill "$PID" > /dev/null 2>&1; then
    echo "WayaGetSystemData stopped."
  else
    echo "Failed to stop WayaGetSystemData (PID: $PID). Process might not be running."
    echo "Searching for related processes..."
    # dist/index.js のパスを修正
    ps aux | grep "node ../dist/index.js" | grep -v grep
  fi
  rm "$PID_FILE"
else
  echo "WayaGetSystemData is not running or app.pid not found."
fi
