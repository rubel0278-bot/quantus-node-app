#!/usr/bin/env bash
# Quantus Network Node — Key Generation Helper
# Generates P2P node key and wormhole keypair for mining rewards

set -euo pipefail

BIN_DIR="/opt/quantus-node/bin"
DATA_DIR="/opt/quantus-node/data"
NODE_KEY_FILE="${DATA_DIR}/node_key.p2p"

echo "═══════════════════════════════════════════════════"
echo "  Quantus Network Node — Key Generation"
echo "═══════════════════════════════════════════════════"

if [[ ! -x "${BIN_DIR}/quantus-node" ]]; then
    echo "ERROR: quantus-node binary not found in ${BIN_DIR}"
    echo "Run install.sh first"
    exit 1
fi

mkdir -p "$DATA_DIR"

# ── P2P Node Key ──────────────────────────────────────────────────────
echo ""
echo "── P2P Node Key ──"
if [[ -f "$NODE_KEY_FILE" ]]; then
    echo "Node key already exists: ${NODE_KEY_FILE}"
    echo "Public key: $(${BIN_DIR}/quantus-node key inspect-node-key --file "$NODE_KEY_FILE" 2>/dev/null || echo 'N/A')"
else
    echo "Generating new P2P node key..."
    "${BIN_DIR}/quantus-node" key generate-node-key --file "$NODE_KEY_FILE"
    chmod 600 "$NODE_KEY_FILE"
    echo "Node key saved: ${NODE_KEY_FILE}"
    echo "Public key: $(${BIN_DIR}/quantus-node key inspect-node-key --file "$NODE_KEY_FILE" 2>/dev/null || echo 'N/A')"
fi

# ── Wormhole Key ──────────────────────────────────────────────────────
echo ""
echo "── Wormhole Key (Mining Rewards) ──"
echo "This generates your wormhole address for receiving mining rewards."
echo "Save the 24-word phrase securely — it controls your rewards!"
echo ""

"${BIN_DIR}/quantus-node" key quantus --scheme wormhole

echo ""
echo "═══════════════════════════════════════════════════"
echo "  IMPORTANT"
echo "═══════════════════════════════════════════════════"
echo "1. Save your 24-word secret phrase securely"
echo "2. Copy the inner_hash value"
echo "3. Set INNER_HASH in /opt/quantus-node/config"
echo "4. Start the node: systemctl start quantus-node"
echo ""
echo "Your mining rewards will be sent to your wormhole address."
echo "If you lose your seed phrase, you lose access to rewards!"
