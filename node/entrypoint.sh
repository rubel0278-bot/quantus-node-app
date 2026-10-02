#!/bin/sh
set -e

# Quantus Node entrypoint.
# Uses the official node binary and the node's built-in solo miner.
# Generated key material and the runtime configuration are persisted under /data.

CONFIG_FILE="${QUANTUS_CONFIG_FILE:-/data/quantus-node.env}"
BASE_PATH="${BASE_PATH:-/data}"

mkdir -p "$(dirname "$CONFIG_FILE")" "$BASE_PATH"

# Create a persistent config file on first start, reuse it on later starts.
if [ ! -f "$CONFIG_FILE" ]; then
  cat > "$CONFIG_FILE" <<EOF
CHAIN=mainnet
NODE_NAME=quantus-node-$(hostname 2>/dev/null || echo container)
BASE_PATH=$BASE_PATH
NODE_KEY_FILE=$BASE_PATH/node_key.p2p
INNER_HASH=
P2P_PORT=30333
RPC_PORT=9944
PROMETHEUS_PORT=9615
SYNC_MODE=full
MAX_BLOCKS_PER_REQUEST=64
EOF
  chmod 600 "$CONFIG_FILE"
fi

# shellcheck disable=SC1090
. "$CONFIG_FILE"

NODE_KEY_FILE="${NODE_KEY_FILE:-$BASE_PATH/node_key.p2p}"
BASE_PATH="${BASE_PATH:-/data}"
CHAIN="${CHAIN:-mainnet}"
NODE_NAME="${NODE_NAME:-quantus-node}"
P2P_PORT="${P2P_PORT:-30333}"
RPC_PORT="${RPC_PORT:-9944}"
PROMETHEUS_PORT="${PROMETHEUS_PORT:-9615}"
SYNC_MODE="${SYNC_MODE:-full}"
MAX_BLOCKS_PER_REQUEST="${MAX_BLOCKS_PER_REQUEST:-64}"

SOLO_MINING_ENABLED=true
if [ -f "$BASE_PATH/dashboard-settings.json" ]; then
  solo="$(sed -n 's/.*"solo_mining_enabled": *\([^,}]*\).*/\1/p' "$BASE_PATH/dashboard-settings.json" | head -n1)"
  pool="$(sed -n 's/.*"pool_mining_enabled": *\([^,}]*\).*/\1/p' "$BASE_PATH/dashboard-settings.json" | head -n1)"
  [ "$solo" = "false" ] && SOLO_MINING_ENABLED=false
fi

if [ ! -f "$NODE_KEY_FILE" ]; then
  mkdir -p "$(dirname "$NODE_KEY_FILE")"
  quantus-node key generate-node-key --file "$NODE_KEY_FILE"
  chmod 600 "$NODE_KEY_FILE"
fi

if [ -z "${INNER_HASH:-}" ]; then
  tmp_output="$(mktemp)"
  if ! quantus-node key quantus --scheme wormhole > "$tmp_output" 2>&1; then
    cat "$tmp_output"
    rm -f "$tmp_output"
    echo "ERROR: failed to generate wormhole inner hash"
    exit 1
  fi
  INNER_HASH="$(sed -n 's/.*\(0x[a-fA-F0-9]\{64\}\).*/\1/p' "$tmp_output" | head -n 1)"
  cat "$tmp_output"
  rm -f "$tmp_output"
  if [ -z "$INNER_HASH" ]; then
    echo "ERROR: could not parse inner hash from wormhole key generation"
    exit 1
  fi
  # Persist the rewards inner hash so restarts keep the same reward destination.
  sed -i "s/^INNER_HASH=.*/INNER_HASH=$INNER_HASH/" "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE"
fi

if [ "$SOLO_MINING_ENABLED" = "true" ]; then
  exec quantus-node \
    --name "$NODE_NAME" \
    --validator \
    --chain "$CHAIN" \
    --base-path "$BASE_PATH" \
    --node-key-file "$NODE_KEY_FILE" \
    --rewards-inner-hash "$INNER_HASH" \
    --port "$P2P_PORT" \
    --rpc-port "$RPC_PORT" \
    --prometheus-port "$PROMETHEUS_PORT" \
    --sync "$SYNC_MODE" \
    --max-blocks-per-request "$MAX_BLOCKS_PER_REQUEST" \
    --rpc-methods safe
else
  exec quantus-node \
    --name "$NODE_NAME" \
    --chain "$CHAIN" \
    --base-path "$BASE_PATH" \
    --node-key-file "$NODE_KEY_FILE" \
    --port "$P2P_PORT" \
    --rpc-port "$RPC_PORT" \
    --prometheus-port "$PROMETHEUS_PORT" \
    --sync "$SYNC_MODE" \
    --max-blocks-per-request "$MAX_BLOCKS_PER_REQUEST" \
    --rpc-methods safe
fi
