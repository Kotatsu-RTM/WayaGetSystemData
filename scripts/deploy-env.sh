#!/bin/bash

ENV_FILE=".env"
SERVER_LIST="servers.txt"
REMOTE_PATH="/path/to/your/app/directory" # Docker Composeファイルがあるリモートパス

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .env file not found. Please run generate_api_key.sh first."
  exit 1
fi

if [ ! -f "$SERVER_LIST" ]; then
  echo "Error: $SERVER_LIST not found. Please create a list of servers (e.g., user@server_ip) in this file."
  exit 1
fi

while IFS= read -r server;
do
  if [ -n "$server" ]; then
    echo "Deploying $ENV_FILE to $server:$REMOTE_PATH"
    scp "$ENV_FILE" "$server:$REMOTE_PATH/$ENV_FILE"
    if [ $? -eq 0 ]; then
      echo "Successfully deployed to $server"
    else
      echo "Failed to deploy to $server"
    fi
  fi
done < "$SERVER_LIST"

echo "Deployment process finished."
