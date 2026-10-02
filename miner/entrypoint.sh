#!/bin/sh
set -e

# Quantus Miner Entrypoint
# Waits for node RPC and credentials before starting miner

echo "Waiting for node JSON-RPC to respond..."
until curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"system_health","params":[]}' \
    http://node:9944 > /dev/null 2>&1; do
  sleep 2
done
echo "Node RPC is ready."

# Wait for credentials to be available
echo "Waiting for miner credentials..."
for i in $(seq 1 60); do
  if [ -f /credentials/miner-auth-token ] && [ -f /credentials/miner-tls-cert-sha256 ]; then
    echo "Credentials found."
    break
  fi
  sleep 1
done

# Verify credentials exist
if [ ! -f /credentials/miner-auth-token ] || [ ! -f /credentials/miner-tls-cert-sha256 ]; then
  echo "ERROR: Credentials not found in /credentials/"
  exit 1
fi

# Read credentials
AUTH_TOKEN=$(cat /credentials/miner-auth-token)
TLS_CERT_SHA256=$(cat /credentials/miner-tls-cert-sha256)

echo "Starting miner, connecting to node:9833..."

exec quantus-miner serve \
  --node-addr node:9833 \
  --auth-token "$AUTH_TOKEN" \
  --tls-cert-sha256 "$TLS_CERT_SHA256" \
  --cpu-workers "${MINER_CPU_WORKERS:-4}" \
  --gpu-devices "${MINER_GPU_DEVICES:-0}" \
  --metrics-port "${MINER_METRICS_PORT:-9900}"
