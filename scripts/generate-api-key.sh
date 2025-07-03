#!/bin/bash

# .envファイルが存在しない場合は作成
if [ ! -f ./.env ]; then
  touch ./.env
fi

# WGS_API_KEYが既に存在するか確認
if grep -q "^WGS_API_KEY=" ./.env; then
  echo "WGS_API_KEY already exists in ./.env. Skipping generation."
else
  # SHA256でランダムなキーを生成
  API_KEY=$(openssl rand -hex 32)
  echo "WGS_API_KEY=${API_KEY}" >> ./.env
  echo "Generated API key and added to ./.env"
fi

echo "Remember to add .env to your .gitignore file."
