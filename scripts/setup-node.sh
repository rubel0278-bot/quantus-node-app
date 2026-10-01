#!/usr/bin/env bash
# Quantus Network Node — Node Binary Setup
# Downloads and installs the quantus-node binary

set -euo pipefail

BIN_DIR="/opt/quantus-node/bin"
ARCH=$(uname -m)

case "$ARCH" in
    x86_64|amd64) GITHUB_ARCH="x86_64-unknown-linux-gnu" ;;
    aarch64|arm64) GITHUB_ARCH="aarch64-unknown-linux-gnu" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Get latest version
VERSION=$(curl -s "https://api.github.com/repos/Quantus-Network/chain/releases/latest" | jq -r '.tag_name')

echo "Downloading quantus-node ${VERSION} (${GITHUB_ARCH})..."

URL="https://github.com/Quantus-Network/chain/releases/download/${VERSION}/quantus-node-${VERSION}-${GITHUB_ARCH}.tar.gz"

mkdir -p "$BIN_DIR"
TMP_FILE=$(mktemp)

curl -fSL --progress-bar -o "$TMP_FILE" "$URL"
tar -xzf "$TMP_FILE" -C "$BIN_DIR"
rm -f "$TMP_FILE"

chmod +x "${BIN_DIR}/quantus-node"
echo "quantus-node installed: $(${BIN_DIR}/quantus-node --version)"
