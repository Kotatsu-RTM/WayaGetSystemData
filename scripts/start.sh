#!/bin/bash
# スクリプトの実行ディレクトリに移動
cd "$(dirname "$0")" || exit

# app.pidのパスを修正
PID_FILE="../app.pid" # ルートディレクトリに配置

if [ -f "$PID_FILE" ]; then
  rm "$PID_FILE"
fi

echo "Starting WayaGetSystemData..."
# server.log は削除されたため、標準出力は/dev/nullにリダイレクト
nohup node ../dist/index.js > /dev/null 2>&1 &
echo $! > "$PID_FILE"
echo "WayaGetSystemData started with PID $!."
echo "Access it via: curl http://localhost:3000/api/systeminfo"
