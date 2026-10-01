#!/usr/bin/env bash
# Quantus Node — StratumOS Init Script
# Called by StratumOS during app installation
# This follows the StratumOS app convention: /opt/<project>/update

set -euo pipefail

ACTION="${1:-install}"
INSTALL_DIR="/opt/quantus-node"

case "$ACTION" in
    install)
        echo "[quantus-node] Running post-install setup..."
        
        # Ensure directories exist
        mkdir -p "${INSTALL_DIR}"/{bin,data,logs,www}
        
        # Set permissions
        chmod 755 "${INSTALL_DIR}"
        chmod 700 "${INSTALL_DIR}/data"
        
        # Reload systemd
        systemctl daemon-reload 2>/dev/null || true
        
        # Enable service
        systemctl enable quantus-node 2>/dev/null || true
        
        echo "[quantus-node] Installation complete"
        echo "[quantus-node] Run: systemctl start quantus-node"
        ;;
    
    update)
        echo "[quantus-node] Running update..."
        "${INSTALL_DIR}/update" --update
        ;;
    
    start)
        systemctl start quantus-node
        ;;
    
    stop)
        systemctl stop quantus-node
        ;;
    
    restart)
        systemctl restart quantus-node
        ;;
    
    status)
        "${INSTALL_DIR}/update" --status
        ;;
    
    uninstall)
        systemctl stop quantus-node 2>/dev/null || true
        systemctl disable quantus-node 2>/dev/null || true
        rm -rf "${INSTALL_DIR}"
        echo "[quantus-node] Uninstalled"
        ;;
    
    *)
        echo "Usage: $0 {install|update|start|stop|restart|status|uninstall}"
        exit 1
        ;;
esac
