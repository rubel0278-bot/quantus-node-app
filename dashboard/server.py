#!/usr/bin/env python3
"""Quantus Node Dashboard - HTTP server for Docker deployment."""

from flask import Flask, jsonify
import requests
import os

app = Flask(__name__)

NODE_RPC_URL = os.environ.get("NODE_RPC_URL", "http://node:9944")
MINER_METRICS_URL = os.environ.get("MINER_METRICS_URL", "http://miner:9900")


@app.route("/")
def index():
    return """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quantus Node Dashboard</title>
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
        .log-output { background: #0d0d15; border-radius: 8px; padding: 1rem; font-family: 'Courier New', monospace; font-size: 0.85rem; max-height: 300px; overflow-y: auto; white-space: pre-wrap; color: #00ff88; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Quantus Network Node</h1>
        <p class="subtitle">5tratumOS Docker Dashboard</p>

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
            <button class="btn btn-primary" onclick="refreshStatus()">Refresh</button>
        </div>

        <div class="card">
            <h2>Node Info</h2>
            <div class="log-output" id="logOutput">Loading...</div>
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
                document.getElementById('peerCount').textContent = data.peers !== undefined ? data.peers : '-';
                document.getElementById('syncStatus').textContent = data.isSyncing ? 'Yes' : 'No';
                document.getElementById('miningStatus').textContent = data.mining ? 'Active' : 'Inactive';
            } catch(e) {
                document.getElementById('nodeStatus').textContent = 'Error';
                document.getElementById('nodeStatus').className = 'status-value error';
            }
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
"""


@app.route("/api/status")
def api_status():
    try:
        # Get node health
        health_resp = requests.post(
            NODE_RPC_URL,
            json={"jsonrpc": "2.0", "id": 1, "method": "system_health", "params": []},
            timeout=5,
        )
        health_data = health_resp.json()
        result = health_data.get("result", {})

        # Get block height
        block_resp = requests.post(
            NODE_RPC_URL,
            json={"jsonrpc": "2.0", "id": 2, "method": "chain_getBlock", "params": []},
            timeout=5,
        )
        block_data = block_resp.json()
        block_result = block_data.get("result", {})
        block_header = block_result.get("block", {}).get("header", {})
        block_number_hex = block_header.get("number", "0x0")
        block_height = int(block_number_hex, 16) if block_number_hex.startswith("0x") else 0

        peers = result.get("peers", [])
        peer_count = len(peers) if isinstance(peers, list) else 0

        return jsonify({
            "status": "running",
            "chain": "mainnet",
            "block_height": block_height,
            "peers": peer_count,
            "isSyncing": result.get("isSyncing", False),
            "shouldHavePeers": result.get("shouldHavePeers", False),
            "mining": True,
        })
    except Exception as e:
        return jsonify({"status": "error", "error": str(e)})


@app.route("/api/logs")
def api_logs():
    return jsonify({"logs": "Logs available via docker logs"})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
