#!/usr/bin/env bash
# Quantus Network Node — Monitoring Script
# Integrates with StratumOS monitoring and Prometheus metrics

set -euo pipefail

INSTALL_DIR="/opt/quantus-node"
DATA_DIR="${INSTALL_DIR}/data"
CONFIG_FILE="${INSTALL_DIR}/config"
METRICS_PORT="${PROMETHEUS_PORT:-9615}"
RPC_PORT="${RPC_PORT:-9944}"

# Source config
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

# ── Check Node Process ────────────────────────────────────────────────
check_process() {
    if pgrep -f "quantus-node" > /dev/null 2>&1; then
        echo "running"
    else
        echo "stopped"
    fi
}

# ── Get Block Height via RPC ──────────────────────────────────────────
get_block_height() {
    local result
    result=$(curl -s -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","id":1,"method":"chain_getBlock","params":[]}' \
        "http://localhost:${RPC_PORT}" 2>/dev/null) || echo ""
    
    if [[ -n "$result" ]]; then
        echo "$result" | jq -r '.result.block.header.number // "unknown"' 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# ── Get Peer Count via RPC ────────────────────────────────────────────
get_peer_count() {
    local result
    result=$(curl -s -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","id":1,"method":"system_networkState","params":[]}' \
        "http://localhost:${RPC_PORT}" 2>/dev/null) || echo ""
    
    if [[ -n "$result" ]]; then
        echo "$result" | jq -r '.result.peerCount // "unknown"' 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# ── Get Sync Status ───────────────────────────────────────────────────
get_sync_status() {
    local result
    result=$(curl -s -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","id":1,"method":"system_syncState","params":[]}' \
        "http://localhost:${RPC_PORT}" 2>/dev/null) || echo ""
    
    if [[ -n "$result" ]]; then
        local current highest
        current=$(echo "$result" | jq -r '.result.currentBlock // "0"' 2>/dev/null || echo "0")
        highest=$(echo "$result" | jq -r '.result.highestBlock // "0"' 2>/dev/null || echo "0")
        if [[ "$current" != "0" && "$highest" != "0" && "$highest" -gt "$current" ]]; then
            local pct=$((current * 100 / highest))
            echo "syncing (${pct}%)"
        elif [[ "$current" != "0" && "$highest" != "0" && "$current" -ge "$highest" ]]; then
            echo "synced"
        else
            echo "idle"
        fi
    else
        echo "unknown"
    fi
}

# ── Get Mining Status ─────────────────────────────────────────────────
get_mining_status() {
    if [[ "${ENABLE_EXTERNAL_MINER:-true}" == "true" ]]; then
        if pgrep -f "quantus-miner" > /dev/null 2>&1; then
            echo "active"
        else
            echo "inactive"
        fi
    else
        echo "local"
    fi
}

# ── Get Disk Usage ────────────────────────────────────────────────────
get_disk_usage() {
    if [[ -d "$DATA_DIR" ]]; then
        du -sh "$DATA_DIR" 2>/dev/null | cut -f1 || echo "unknown"
    else
        echo "0"
    fi
}

# ── Get Memory Usage ──────────────────────────────────────────────────
get_memory_usage() {
    free -m | awk 'NR==2{printf "%.0f%%", $3*100/$2}'
}

# ── Get CPU Usage ─────────────────────────────────────────────────────
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
}

# ── Output JSON Status ────────────────────────────────────────────────
output_json() {
    local status block_height peers sync mining disk memory cpu
    status=$(check_process)
    block_height=$(get_block_height)
    peers=$(get_peer_count)
    sync=$(get_sync_status)
    mining=$(get_mining_status)
    disk=$(get_disk_usage)
    memory=$(get_memory_usage)
    cpu=$(get_cpu_usage)

    cat << EOF
{
    "status": "${status}",
    "chain": "${CHAIN:-mainnet}",
    "block_height": "${block_height}",
    "peers": "${peers}",
    "syncing": "${sync}",
    "mining": "${mining}",
    "disk_usage": "${disk}",
    "memory_usage": "${memory}",
    "cpu_usage": "${cpu}",
    "timestamp": "$(date -Iseconds)"
}
EOF
}

# ── Output Prometheus Metrics ─────────────────────────────────────────
output_prometheus() {
    local status block_height peers
    status=$(check_process)
    block_height=$(get_block_height)
    peers=$(get_peer_count)

    echo "# HELP quantus_node_running Whether the node is running (1) or not (0)"
    echo "# TYPE quantus_node_running gauge"
    echo "quantus_node_running $([[ "$status" == "running" ]] && echo 1 || echo 0)"

    echo "# HELP quantus_node_block_height Current block height"
    echo "# TYPE quantus_node_block_height gauge"
    echo "quantus_node_block_height ${block_height}"

    echo "# HELP quantus_node_peers Number of connected peers"
    echo "# TYPE quantus_node_peers gauge"
    echo "quantus_node_peers ${peers}"

    echo "# HELP quantus_node_chain Chain name"
    echo "# TYPE quantus_node_chain gauge"
    echo "quantus_node_chain{chain=\"${CHAIN:-mainnet}\"} 1"
}

# ── Main ──────────────────────────────────────────────────────────────
case "${1:-}" in
    --json|json)
        output_json
        ;;
    --prometheus|prometheus)
        output_prometheus
        ;;
    *)
        echo "Quantus Node Monitor"
        echo "  Status:     $(check_process)"
        echo "  Chain:      ${CHAIN:-mainnet}"
        echo "  Block:      $(get_block_height)"
        echo "  Peers:      $(get_peer_count)"
        echo "  Sync:       $(get_sync_status)"
        echo "  Mining:     $(get_mining_status)"
        echo "  Disk:       $(get_disk_usage)"
        echo "  Memory:     $(get_memory_usage)"
        echo "  CPU:        $(get_cpu_usage)"
        ;;
esac
