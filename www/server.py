#!/usr/bin/env python3
"""
Quantus Node — StratumOS Dashboard Server
Simple HTTP server for the web dashboard.
"""

import http.server
import json
import subprocess
import os
from datetime import datetime

INSTALL_DIR = "/opt/quantus-node"
CONFIG_FILE = f"{INSTALL_DIR}/config"
RPC_PORT = 9944
DASHBOARD_PORT = 8080


def load_config():
    config = {}
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    key, _, value = line.partition("=")
                    config[key.strip()] = value.strip().strip('"').strip("'")
    return config


def get_status():
    config = load_config()
    try:
        result = subprocess.run(
            ["systemctl", "is-active", "quantus-node"],
            capture_output=True, text=True, timeout=5
        )
        running = result.stdout.strip() == "active"
    except Exception:
        running = False

    try:
        result = subprocess.run(
            ["curl", "-s", "-H", "Content-Type: application/json",
             "-d", '{"jsonrpc":"2.0","id":1,"method":"chain_getBlock","params":[]}',
             f"http://localhost:{RPC_PORT}"],
            capture_output=True, text=True, timeout=5
        )
        data = json.loads(result.stdout)
        block_height = data.get("result", {}).get("block", {}).get("header", {}).get("number", "unknown")
    except Exception:
        block_height = "unknown"

    try:
        result = subprocess.run(
            ["curl", "-s", "-H", "Content-Type: application/json",
             "-d", '{"jsonrpc":"2.0","id":1,"method":"system_networkState","params":[]}',
             f"http://localhost:{RPC_PORT}"],
            capture_output=True, text=True, timeout=5
        )
        data = json.loads(result.stdout)
        peers = data.get("result", {}).get("peerCount", "unknown")
    except Exception:
        peers = "unknown"

    return {
        "status": "running" if running else "stopped",
        "chain": config.get("CHAIN", "mainnet"),
        "block_height": block_height,
        "peers": peers,
        "mining": "active" if config.get("ENABLE_EXTERNAL_MINER", "true") == "true" else "local",
        "timestamp": datetime.now().isoformat()
    }


def get_logs(lines=100):
    try:
        result = subprocess.run(
            ["journalctl", "-u", "quantus-node", "-n", str(lines), "--no-pager", "-q"],
            capture_output=True, text=True, timeout=5
        )
        return result.stdout
    except Exception:
        return "Failed to load logs"


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/status":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps(get_status()).encode())
        elif self.path == "/api/logs":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(get_logs().encode())
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
                if action == "start":
                    subprocess.run(["systemctl", "start", "quantus-node"], timeout=10)
                elif action == "stop":
                    subprocess.run(["systemctl", "stop", "quantus-node"], timeout=10)
                elif action == "restart":
                    subprocess.run(["systemctl", "restart", "quantus-node"], timeout=10)
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"success": True, "action": action}).encode())
            except Exception as e:
                self.send_response(500)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"success": False, "error": str(e)}).encode())
        else:
            self.send_error(404)

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
        pass


def main():
    with http.server.HTTPServer(("", DASHBOARD_PORT), Handler) as httpd:
        print(f"Quantus Node Dashboard running on port {DASHBOARD_PORT}")
        httpd.serve_forever()


if __name__ == "__main__":
    main()
