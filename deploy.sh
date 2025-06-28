#!/bin/bash
# Скрипт запуска агента через Docker

# Проверяем что запущено на сервере Linux|Ubuntu 18.04+
if [ "$(uname -s)" != "Linux" ]; then
  echo "This script is intended to run on Linux systems only."
  exit 1
fi

if [ "$(lsb_release -is)" != "Ubuntu" ] || [ "$(lsb_release -rs)" != "18.04" ] && [ "$(lsb_release -rs)" != "20.04" ] && [ "$(lsb_release -rs)" != "22.04" ]; then
  echo "This script is intended to run on Ubuntu 18.04+"
  exit 1
fi

# Проверям что запущено от root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo."
  exit 1
fi

# Устанавливаем переменные окружения
MASTER_URL=${MASTER_URL:-"http://master-node/api/node/register"}
NODE_UUID=${NODE_UUID:-$(cat /proc/sys/kernel/random/uuid)}

# Проверяем наличие Docker
if ! command -v docker &> /dev/null; then
  echo "Docker is not installed. Installing Docker."
  curl -fsSL https://get.docker.com | sh
fi

# Проверяем наличие jq для обработки JSON
if ! command -v jq &> /dev/null; then
  echo "jq is not installed. Installing jq."
  apt-get update && apt-get install -y jq
fi

# Проверяем наличие curl для HTTP-запросов
if ! command -v curl &> /dev/null; then
  echo "curl is not installed. Installing curl."
  apt-get update && apt-get install -y curl
fi

# Override with command line argument if provided
if [ -n "$1" ]; then
  MASTER_URL="$1"
  echo "Using provided MASTER_URL: $MASTER_URL"
else
  echo "Using default MASTER_URL: $MASTER_URL"
fi

echo "Using NODE_UUID: $NODE_UUID"

# Prepare registration data
REGISTER_DATA=$(jq -n \
  --arg uuid "$NODE_UUID" \
  '{
    "node_uuid": $uuid
  }')

echo "Attempting to register node with master..."

# Make POST request to register
RESPONSE=$(curl -s -S -X POST \
  -H "Content-Type: application/json" \
  -d "$REGISTER_DATA" \
  --max-time 10 \
  --write-out "\nHTTP_STATUS:%{http_code}" \
  "$MASTER_URL")

# Extract HTTP status and body
HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d':' -f2)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS:/d')

# Process response
if [ "$HTTP_STATUS" -eq 200 ] || [ "$HTTP_STATUS" -eq 201 ]; then
  echo "Node registered successfully!"
  echo "Response: $RESPONSE_BODY"
else
  echo "Error: Failed to register node (HTTP $HTTP_STATUS)" >&2
  echo "Response: $RESPONSE_BODY" >&2
  exit 1
fi

echo "Starting node agent with UUID: $NODE_UUID"
echo "Connecting to master at: $MASTER_URL"

# Build and run Docker container
docker build -t node-agent . || {
  echo "Failed to build Docker image"
  exit 1
}

docker run -d --rm \
  --name node-agent \
  -e NODE_UUID="$NODE_UUID" \
  -e MASTER_URL="$MASTER_URL" \
  --privileged \
  --network host \
  node-agent || {
  echo "Failed to start Docker container"
  exit 1
}

echo "Node agent started successfully"
