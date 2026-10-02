#!/bin/sh
set -e

# Quantus Node Entrypoint Wrapper
# Starts the node and copies miner credentials to shared volume

echo "Starting Quantus node..."

# Start node in background
quantus-node \
  --chain mainnet \
  --base-path /data \
  --miner-listen-port 9833 \
  --rpc-methods safe \
  --sync full &
NODE_PID=$!

# Wait for credentials to be generated
echo "Waiting for miner credentials to be generated..."
for i in $(seq 1 60); do
  if [ -f /data/chains/mainnet/miner-auth-token ] && [ -f /data/chains/mainnet/miner-tls-cert-sha256 ]; then
    echo "Credentials found, copying to shared volume..."
    cp /data/chains/mainnet/miner-auth-token /credentials/miner-auth-token
    cp /data/chains/mainnet/miner-tls-cert-sha256 /credentials/miner-tls-cert-sha256
    chmod 600 /credentials/miner-auth-token
    chmod 644 /credentials/miner-tls-cert-sha256
    echo "Credentials copied successfully."
    break
  fi
  sleep 1
done

# Verify credentials were copied
if [ ! -f /credentials/miner-auth-token ] || [ ! -f /credentials/miner-tls-cert-sha256 ]; then
  echo "ERROR: Failed to copy credentials to shared volume"
  exit 1
fi

# Wait for node process
wait $NODE_PID
