#!/usr/bin/env bash
# Quantus Network Node — StratumOS Installation Script
# Usage: install.sh [--full] [--force] [--uninstall]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="quantus-node"
INSTALL_DIR="/opt/${APP_NAME}"
DATA_DIR="${INSTALL_DIR}/data"
BIN_DIR="${INSTALL_DIR}/bin"
LOG_DIR="${INSTALL_DIR}/logs"
SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"
CONFIG_FILE="${INSTALL_DIR}/config"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[quantus-node]${NC} $*"; }
warn() { echo -e "${YELLOW}[quantus-node]${NC} $*"; }
error() { echo -e "${RED}[quantus-node]${NC} $*" >&2; }
info() { echo -e "${BLUE}[quantus-node]${NC} $*"; }

# ── Detect Architecture ───────────────────────────────────────────────
detect_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64) echo "x86_64-unknown-linux-gnu" ;;
        aarch64|arm64) echo "aarch64-unknown-linux-gnu" ;;
        *) error "Unsupported architecture: $arch"; exit 1 ;;
    esac
}

# ── Detect Latest Release ─────────────────────────────────────────────
get_latest_release() {
    local repo="$1"
    curl -s "https://api.github.com/repos/${repo}/releases/latest" | \
        jq -r '.tag_name // empty' 2>/dev/null || echo ""
}

# ── Download Binary ───────────────────────────────────────────────────
# Handles two asset naming conventions:
#   Node:   quantus-node-{version}-{arch}.tar.gz
#   Miner:  quantus-miner-{platform}  (no version, no extension)
download_binary() {
    local repo="$1"
    local version="$2"
    local arch="$3"
    local output_dir="$4"
    local binary_name="$5"

    local asset_name url

    if [[ "$binary_name" == "quantus-miner" ]]; then
        # Miner uses platform-only naming: quantus-miner-linux-x86_64
        local platform
        case "$arch" in
            x86_64-unknown-linux-gnu) platform="linux-x86_64" ;;
            aarch64-unknown-linux-gnu) platform="linux-aarch64" ;;
            *) error "Unsupported miner architecture: $arch"; return 1 ;;
        esac
        asset_name="${binary_name}-${platform}"
    else
        # Node uses standard naming: quantus-node-{version}-{arch}.tar.gz
        asset_name="${binary_name}-${version}-${arch}.tar.gz"
    fi

    url="https://github.com/${repo}/releases/download/${version}/${asset_name}"

    info "Downloading ${binary_name} ${version} (${arch})..."
    info "URL: ${url}"

    mkdir -p "$output_dir"
    local tmp_file
    tmp_file=$(mktemp)

    if ! curl -fSL --progress-bar -o "$tmp_file" "$url" 2>&1; then
        error "Failed to download ${binary_name}"
        rm -f "$tmp_file"
        return 1
    fi

    # Try tar extraction first, fall back to raw binary copy
    if tar -xzf "$tmp_file" -C "$output_dir" 2>/dev/null; then
        :
    elif tar -xf "$tmp_file" -C "$output_dir" 2>/dev/null; then
        :
    else
        cp "$tmp_file" "${output_dir}/${binary_name}"
    fi
    rm -f "$tmp_file"

    chmod +x "${output_dir}/${binary_name}"
    log "Installed ${binary_name} to ${output_dir}"
}

# ── Install Dependencies ──────────────────────────────────────────────
install_dependencies() {
    log "Installing dependencies..."
    if command -v apt-get &>/dev/null; then
        apt-get update -qq
        apt-get install -y -qq curl wget tar jq 2>/dev/null
    elif command -v yum &>/dev/null; then
        yum install -y curl wget tar jq 2>/dev/null
    else
        warn "Unknown package manager — please install: curl, wget, tar, jq"
    fi
}

# ── Create Directory Structure ────────────────────────────────────────
create_directories() {
    log "Creating directory structure..."
    mkdir -p "$INSTALL_DIR" "$DATA_DIR" "$BIN_DIR" "$LOG_DIR"
    mkdir -p "${DATA_DIR}/chains"
    chmod 755 "$INSTALL_DIR"
}

# ── Generate Node Key ─────────────────────────────────────────────────
generate_node_key() {
    if [[ -f "$NODE_KEY_FILE" ]]; then
        warn "Node key already exists at ${NODE_KEY_FILE} — skipping generation"
        return 0
    fi

    log "Generating P2P node key..."
    "${BIN_DIR}/quantus-node" key generate-node-key --file "$NODE_KEY_FILE"
    chmod 600 "$NODE_KEY_FILE"
    log "Node key saved to ${NODE_KEY_FILE}"
}

# ── Generate Wormhole Key ─────────────────────────────────────────────
generate_wormhole_key() {
    if [[ -n "$INNER_HASH" ]]; then
        info "Using existing INNER_HASH from config"
        return 0
    fi

    log "Generating wormhole keypair for mining rewards..."
    local output
    output=$("${BIN_DIR}/quantus-node" key quantus --scheme wormhole 2>&1) || {
        error "Failed to generate wormhole key"
        echo "$output"
        return 1
    }

    echo "$output"

    local inner_hash
    inner_hash=$(echo "$output" | grep -i "inner_hash" | awk '{print $NF}' || echo "")

    if [[ -n "$inner_hash" ]]; then
        INNER_HASH="$inner_hash"
        # Update config file
        sed -i "s/^INNER_HASH=.*/INNER_HASH=\"${INNER_HASH}\"/" "$CONFIG_FILE"
        log "Wormhole inner hash saved to config"
    else
        warn "Could not extract inner_hash from output — please set INNER_HASH manually in ${CONFIG_FILE}"
    fi
}

# ── Create Systemd Service ────────────────────────────────────────────
create_service() {
    log "Creating systemd service..."

    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Quantus Network Node
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_DIR}
Environment="RUST_LOG=${LOG_LEVEL}"
ExecStart=${BIN_DIR}/quantus-node \\
    --name "${NODE_NAME}" \\
    --validator \\
    --chain ${CHAIN} \\
    --base-path ${BASE_PATH} \\
    --node-key-file ${NODE_KEY_FILE} \\
    --rewards-inner-hash ${INNER_HASH} \\
    --port ${P2P_PORT} \\
    --rpc-port ${RPC_PORT} \\
    --prometheus-port ${PROMETHEUS_PORT} \\
    --sync ${SYNC_MODE} \\
    --max-blocks-per-request ${MAX_BLOCKS_PER_REQUEST} \\
    --rpc-methods safe
ExecStop=/bin/kill -TERM \$MAINPID
Restart=on-failure
RestartSec=10
StandardOutput=append:${LOG_DIR}/quantus-node.log
StandardError=append:${LOG_DIR}/quantus-node.log

# Security
NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths=${DATA_DIR} ${LOG_DIR}

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    log "Service created: ${SERVICE_FILE}"
}

# ── Configure Firewall ────────────────────────────────────────────────
configure_firewall() {
    log "Configuring firewall..."

    if command -v ufw &>/dev/null; then
        ufw allow ${P2P_PORT}/tcp comment "Quantus P2P" 2>/dev/null || true
        # Miner port stays private
        ufw deny ${MINER_PORT}/udp comment "Quantus Miner (private)" 2>/dev/null || true
        ufw deny ${RPC_PORT}/tcp comment "Quantus RPC (private)" 2>/dev/null || true
        ufw deny ${PROMETHEUS_PORT}/tcp comment "Quantus Metrics (private)" 2>/dev/null || true
        log "UFW rules configured"
    elif command -v firewall-cmd &>/dev/null; then
        firewall-cmd --permanent --add-port=${P2P_PORT}/tcp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
        log "firewalld rules configured"
    else
        warn "No firewall detected — please manually configure ports"
    fi
}

# ── Create StratumOS Integration ──────────────────────────────────────
create_stratum_integration() {
    log "Creating StratumOS integration..."

    # Create symlink for stratum command
    ln -sf "${INSTALL_DIR}/update" "/usr/local/bin/quantus-node-ctl" 2>/dev/null || true

    # Create web dashboard
    mkdir -p "${INSTALL_DIR}/www"
    cat > "${INSTALL_DIR}/www/index.html" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quantus Node — StratumOS</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0a0a0f; color: #e0e0e0; min-height: 100vh; padding: 2rem; }
        .container { max-width: 900px; margin: 0 auto; }
        h1 { color: #00d4ff; margin-bottom: 0.5rem; font-size: 2rem; }
        .subtitle { color: #888; margin-bottom: 2rem; }
        .card { background: #151520; border: 1px solid #252535; border-radius: 12px; padding: 1.5rem; margin-bottom: 1.5rem; }
        .card h2 { color: #00d4ff; margin-bottom: 1rem; font-size: 1.1rem; text-transform: uppercase; letter-spacing: 1px; }
        .status-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; }
        .status-item { background: #1a1a2e; padding: 1rem; border-radius: 8px; }
        .status-label { color: #888; font-size: 0.8rem; text-transform: uppercase; }
        .status-value { color: #00ff88; font-size: 1.3rem; font-weight: bold; margin-top: 0.3rem; }
        .status-value.warning { color: #ffaa00; }
        .status-value.error { color: #ff4444; }
        .btn { display: inline-block; padding: 0.6rem 1.2rem; border-radius: 6px; border: none; cursor: pointer; font-size: 0.9rem; font-weight: 600; text-decoration: none; margin: 0.3rem; }
        .btn-primary { background: #00d4ff; color: #000; }
        .btn-danger { background: #ff4444; color: #fff; }
        .btn-warning { background: #ffaa00; color: #000; }
        .log-output { background: #0d0d15; border-radius: 8px; padding: 1rem; font-family: 'Courier New', monospace; font-size: 0.85rem; max-height: 300px; overflow-y: auto; white-space: pre-wrap; color: #00ff88; }
        .refresh-btn { float: right; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Quantus Network Node</h1>
        <p class="subtitle">StratumOS Management Dashboard</p>

        <div class="card">
            <h2>Node Status</h2>
            <div class="status-grid" id="statusGrid">
                <div class="status-item">
                    <div class="status-label">Status</div>
                    <div class="status-value" id="nodeStatus">Loading...</div>
                </div>
                <div class="status-item">
                    <div class="status-label">Chain</div>
                    <div class="status-value" id="chainName">-</div>
                </div>
                <div class="status-item">
                    <div class="status-label">Block Height</div>
                    <div class="status-value" id="blockHeight">-</div>
                </div>
                <div class="status-item">
                    <div class="status-label">Peers</div>
                    <div class="status-value" id="peerCount">-</div>
                </div>
                <div class="status-item">
                    <div class="status-label">Syncing</div>
                    <div class="status-value" id="syncStatus">-</div>
                </div>
                <div class="status-item">
                    <div class="status-label">Mining</div>
                    <div class="status-value" id="miningStatus">-</div>
                </div>
            </div>
        </div>

        <div class="card">
            <h2>Actions</h2>
            <button class="btn btn-primary" onclick="controlNode('start')">Start</button>
            <button class="btn btn-danger" onclick="controlNode('stop')">Stop</button>
            <button class="btn btn-warning" onclick="controlNode('restart')">Restart</button>
            <button class="btn btn-primary" onclick="refreshStatus()">Refresh</button>
        </div>

        <div class="card">
            <h2>Recent Logs</h2>
            <div class="log-output" id="logOutput">Loading logs...</div>
        </div>
    </div>

    <script>
        async function refreshStatus() {
            try {
                const resp = await fetch('/api/status');
                const data = await resp.json();
                document.getElementById('nodeStatus').textContent = data.status || 'Unknown';
                document.getElementById('nodeStatus').className = 'status-value ' + (data.status === 'running' ? '' : 'warning');
                document.getElementById('chainName').textContent = data.chain || '-';
                document.getElementById('blockHeight').textContent = data.block_height || '-';
                document.getElementById('peerCount').textContent = data.peers || '-';
                document.getElementById('syncStatus').textContent = data.syncing ? 'Yes' : 'No';
                document.getElementById('miningStatus').textContent = data.mining ? 'Active' : 'Inactive';
            } catch(e) {
                document.getElementById('nodeStatus').textContent = 'Error';
                document.getElementById('nodeStatus').className = 'status-value error';
            }
        }

        async function controlNode(action) {
            await fetch('/api/control', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({action})
            });
            setTimeout(refreshStatus, 2000);
        }

        async function loadLogs() {
            try {
                const resp = await fetch('/api/logs');
                const data = await resp.json();
                document.getElementById('logOutput').textContent = data.logs || 'No logs available';
            } catch(e) {
                document.getElementById('logOutput').textContent = 'Failed to load logs';
            }
        }

        refreshStatus();
        loadLogs();
        setInterval(refreshStatus, 10000);
    </script>
</body>
</html>
HTMLEOF

    log "Web dashboard created"
}

# ── Main Installation ─────────────────────────────────────────────────
main() {
    local mode="${1:-}"

    log "═══════════════════════════════════════════════════"
    log "  Quantus Network Node — StratumOS Installer"
    log "═══════════════════════════════════════════════════"

    # Check root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        exit 1
    fi

    # Install dependencies
    install_dependencies

    # Create directories
    create_directories

    # Copy config if not exists
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cp "${SCRIPT_DIR}/config" "$CONFIG_FILE"
        log "Default config installed to ${CONFIG_FILE}"
    fi

    # Source config
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"

    # Detect architecture
    local arch
    arch=$(detect_arch)
    info "Architecture: ${arch}"

    # Get versions
    local node_version="$NODE_VERSION"
    if [[ -z "$node_version" ]]; then
        node_version=$(get_latest_release "Quantus-Network/chain")
    fi

    local miner_version="$MINER_VERSION"
    if [[ -z "$miner_version" ]]; then
        miner_version=$(get_latest_release "Quantus-Network/quantus-miner")
    fi

    info "Node version: ${node_version}"
    info "Miner version: ${miner_version}"

    # Download binaries
    download_binary "Quantus-Network/chain" "$node_version" "$arch" "$BIN_DIR" "quantus-node"

    if [[ "$ENABLE_EXTERNAL_MINER" == "true" && -n "$miner_version" ]]; then
        download_binary "Quantus-Network/quantus-miner" "$miner_version" "$arch" "$BIN_DIR" "quantus-miner" || {
            warn "Failed to download miner — continuing with node only"
            ENABLE_EXTERNAL_MINER=false
        }
    fi

    # Generate keys
    generate_node_key
    generate_wormhole_key

    # Create service
    create_service

    # Configure firewall
    configure_firewall

    # Create StratumOS integration
    create_stratum_integration

    # Enable and start service
    systemctl enable "$APP_NAME" 2>/dev/null || true

    if [[ "$mode" == "--full" ]]; then
        log "Starting node..."
        systemctl start "$APP_NAME" 2>/dev/null || warn "Failed to start service — check logs"
    fi

    # Create update script
    cp "${SCRIPT_DIR}/update" "${INSTALL_DIR}/update"
    chmod +x "${INSTALL_DIR}/update"

    log "═══════════════════════════════════════════════════"
    log "  Installation Complete!"
    log "═══════════════════════════════════════════════════"
    info "Config:    ${CONFIG_FILE}"
    info "Data:      ${DATA_DIR}"
    info "Logs:      ${LOG_DIR}"
    info "Service:  systemctl ${APP_NAME} {start|stop|restart|status}"
    info "Dashboard: http://localhost:${DASHBOARD_PORT}"
    info ""
    info "Next steps:"
    info "  1. Edit ${CONFIG_FILE} to set your INNER_HASH"
    info "  2. Run: systemctl start ${APP_NAME}"
    info "  3. Check status: systemctl status ${APP_NAME}"
    info "  4. View logs: journalctl -u ${APP_NAME} -f"
}

main "$@"
