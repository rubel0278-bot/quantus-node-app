#!/usr/bin/env python3
"""
Quantus Node — StratumOS Dashboard API
Lightweight HTTP API for the StratumOS web dashboard.
Serves node status, logs, and control endpoints.
"""

import json
import subprocess
import os
import http.server
import socketserver
from datetime import datetime

INSTALL_DIR = "/opt/quantus-node"
CONFIG_FILE = f"{INSTALL_DIR}/config"
LOG_DIR = f"{INSTALL_DIR}/logs"
RPC_PORT = 9944
DASHBOARD_PORT = 8080


def load_config():
    """Load the config file as a dict."""
    config = {}
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    key, _, value = line.partition("=")
                    config[key.strip()] = value.strip().strip('"').strip("'")
    return config


def get_service_status():
    """Check if the systemd service is running."""
    try:
        result = subprocess.run(
            ["systemctl", "is-active", "quantus-node"],
            capture_output=True, text=True, timeout=5
        )
        return result.stdout.strip() == "active"
    except Exception:
        return False


def get_block_height():
    """Get current block height via RPC."""
    try:
        result = subprocess.run(
            ["curl", "-s", "-H", "Content-Type: application/json",
             "-d", '{"jsonrpc":"2.0","id":1,"method":"chain_getBlock","params":[]}',
             f"http://localhost:{RPC_PORT}"],
            capture_output=True, text=True, timeout=5
        )
        data = json.loads(result.stdout)
        return data.get("result", {}).get("block", {}).get("header", {}).get("number", "unknown")
    except Exception:
        return "unknown"


def get_peer_count():
    """Get peer count via RPC."""
    try:
        result = subprocess.run(
            ["curl", "-s", "-H", "Content-Type: application/json",
             "-d", '{"jsonrpc":"2.0","id":1,"method":"system_networkState","params":[]}',
             f"http://localhost:{RPC_PORT}"],
            capture_output=True, text=True, timeout=5
        )
        data = json.loads(result.stdout)
        return data.get("result", {}).get("peerCount", "unknown")
    except Exception:
        return "unknown"


def get_sync_state():
    """Get sync state via RPC."""
    try:
        result = subprocess.run(
            ["curl", "-s", "-H", "Content-Type: application/json",
             "-d", '{"jsonrpc":"2.0","id":1,"method":"system_syncState","params":[]}',
             f"http://localhost:{RPC_PORT}"],
            capture_output=True, text=True, timeout=5
        )
        data = json.loads(result.stdout)
        current = int(data.get("result", {}).get("currentBlock", "0"))
        starting = int(data.get("result", {}).get("startingBlock", "0"))
        if current > 0 and starting > 0:
            pct = min(100, int(current * 100 / max(current, starting + 1)))
            return f"syncing ({pct}%)"
        return "idle"
    except Exception:
        return "unknown"


def get_logs(lines=50):
    """Get recent log lines."""
    try:
        result = subprocess.run(
            ["journalctl", "-u", "quantus-node", "-n", str(lines), "--no-pager", "-q"],
            capture_output=True, text=True, timeout=5
        )
        return result.stdout
    except Exception:
        return "Failed to load logs"


def control_node(action):
    """Control the node service."""
    try:
        if action == "start":
            subprocess.run(["systemctl", "start", "quantus-node"], timeout=10)
        elif action == "stop":
            subprocess.run(["systemctl", "stop", "quantus-node"], timeout=10)
        elif action == "restart":
            subprocess.run(["systemctl", "restart", "quantus-node"], timeout=10)
        return True
    except Exception:
        return False


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/status":
            config = load_config()
            status = {
                "status": "running" if get_service_status() else "stopped",
                "chain": config.get("CHAIN", "mainnet"),
                "block_height": get_block_height(),
                "peers": get_peer_count(),
                "syncing": get_sync_state(),
                "mining": "active" if config.get("ENABLE_EXTERNAL_MINER", "true") == "true" else "local",
                "timestamp": datetime.now().isoformat()
            }
            self.send_json(status)
        elif self.path == "/api/logs":
            self.send_text(get_logs(100))
        elif self.path == "/" or self.path == "/index.html":
            self.serve_dashboard()
        else:
            self.send_error(404)

    def do_POST(self):
        if self.path == "/api/control":
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length)
            try:
                data = json.loads(body)
                action = data.get("action", "")
                success = control_node(action)
                self.send_json({"success": success, "action": action})
            except Exception as e:
                self.send_json({"success": False, "error": str(e)})
        else:
            self.send_error(404)

    def send_json(self, data):
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def send_text(self, text):
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(text.encode())

    def serve_dashboard(self):
        dashboard_path = f"{INSTALL_DIR}/www/index.html"
        if os.path.exists(dashboard_path):
            with open(dashboard_path) as f:
                content = f.read()
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(content.encode())
        else:
            self.send_error(404)

    def log_message(self, format, *args):
        pass  # Suppress request logs


def main():
    port = DASHBOARD_PORT
    with socketserver.TCPServer(("", port), Handler) as httpd:
        print(f"Quantus Node Dashboard API running on port {port}")
        httpd.serve_forever()


if __name__ == "__main__":
    main()
