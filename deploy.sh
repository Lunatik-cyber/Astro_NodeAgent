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

# Проверяем наличие необходимых переменных окружения
if [ -z "$NODE_UUID" ]; then
  echo "NODE_UUID is not set. Generating a new UUID."
fi

# Проверяем наличие переменной окружения MASTER_URL
if [ -z "$MASTER_URL" ]; then
  echo "MASTER_URL is not set. Using default: http://master-node/api/node/deploy"
fi

# Проверяем наличие Docker
if ! command -v docker &> /dev/null; then
  echo "Docker is not installed. Please install Docker to run this script."
  exit 1
fi

# Проверяем наличие jq для обработки JSON
if ! command -v jq &> /dev/null; then
  echo "jq is not installed. Please install jq to run this script."
  exit 1
fi

# Проверяем наличие curl для HTTP-запросов
if ! command -v curl &> /dev/null; then
  echo "curl is not installed. Please install curl to run this script."
  exit 1
fi

# Устанавливаем переменные окружения
NODE_UUID=${NODE_UUID:-""}
# Если NODE_UUID не задан, генерируем новый UUID
if [ -z "$NODE_UUID" ]; then
  NODE_UUID=$(cat /proc/sys/kernel/random/uuid)
  echo "Generated new NODE_UUID: $NODE_UUID"
else
  echo "Using provided NODE_UUID: $NODE_UUID"
fi

# Устанавливаем переменную окружения для Docker
export NODE_UUID="$NODE_UUID"

# Устанавливаем URL для мастера, если он не задан $1 или используем дефот
# Set default MASTER_URL
MASTER_URL=${MASTER_URL:-"http://master-node/api/node/register"}

# Override with command line argument if provided
if [ -n "$1" ]; then
  MASTER_URL="$1"
  echo "Using provided MASTER_URL: $MASTER_URL"
else
  echo "Using default MASTER_URL: $MASTER_URL"
fi

# Check URL reachability with timeout
if ! curl --max-time 5 --output /dev/null --silent --head --fail "$MASTER_URL"; then
  echo "Error: Master URL is not reachable: $MASTER_URL" >&2
  exit 1
fi

# Generate or use existing NODE_UUID
if [ -z "$NODE_UUID" ]; then
  NODE_UUID=$(uuidgen)
  echo "NODE_UUID is not set. Generating a new UUID."
  echo "Generated new NODE_UUID: $NODE_UUID"
else
  echo "Using existing NODE_UUID: $NODE_UUID"
fi

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

# Устанавливаем необходимые зависимости
apt update && apt install -y \
    docker.io \
    jq \
    curl

echo "Starting node agent with UUID: $NODE_UUID"
echo "Connecting to master at: $MASTER_URL"
curl -X POST "$MASTER_URL" \
    -H "Content-Type: application/json" \
    -d "{\"uuid\": \"$NODE_UUID\"}" \
    --fail --silent --show-error || {
    echo "Failed to register node with master."
    exit 1

docker build -t node-agent .

docker run -d --rm \
    --name node-agent \
    -e NODE_UUID="$NODE_UUID" \
    -e MASTER_URL="$MASTER_URL" \
    --privileged \
    --network host \
    node-agent 
