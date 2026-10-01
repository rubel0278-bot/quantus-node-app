# Quantus Network Node — StratumOS Application

A complete StratumOS application for running a Quantus Network node with QPoW mining support.

## Overview

This application installs, configures, and manages a Quantus Network node on StratumOS. It supports:

- **Mainnet** (`mainnet`) — live Quantus network with QTC token
- **Testnet** (`heisenberg`) — public testnet
- **Automatic binary download** from official GitHub releases
- **Wormhole address generation** for mining rewards
- **External miner support** via QUIC protocol
- **Systemd service** for auto-start and restart
- **StratumOS integration** for remote monitoring

## StratumOS App Store Installation

### Repository Structure

This repository follows the StratumOS app format:

```
quantus-node-app/
├── README.md              # This file
├── app.json               # App manifest for StratumOS app store
├── install.sh             # Main installation script
├── update                 # Update script (downloaded by StratumOS)
├── config                 # Default configuration
├── service/
│   └── quantus-node.service  # Systemd service file
├── scripts/
│   ├── setup-node.sh      # Node binary setup
│   ├── generate-keys.sh   # Key generation helper
│   └── monitor.sh         # Monitoring script
└── www/
    └── index.html         # Web dashboard for StratumOS panel
```

### Installation on StratumOS

1. **Sync this repository** to your StratumOS machine:

```bash
# On your StratumOS machine, as root:
cd /opt
git clone https://github.com/YOUR_USERNAME/quantus-node-app.git quantus-node
cd quantus-node
chmod +x install.sh
./install.sh --full
```

2. **Or use the StratumOS app store** (if published):

```bash
stratum --action=install --app=quantus-node
```

### Quick Start

```bash
# Full installation (binary + keys + service)
/opt/quantus-node/install.sh --full

# Start mining
/opt/quantus-node/update --start

# Check status
/opt/quantus-node/update --status

# View logs
/opt/quantus-node/update --logs
```

## Configuration

Edit `/opt/quantus-node/config` to customize:

```bash
# Chain: mainnet or heisenberg
CHAIN=mainnet

# Node display name (shown on telemetry)
NODE_NAME="my-stratum-node"

# Mining rewards (wormhole inner hash — 32-byte hex)
INNER_HASH=""

# Node key file path
NODE_KEY_FILE="/opt/quantus-node/data/node_key.p2p"

# Data directory
BASE_PATH="/opt/quantus-node/data"

# Ports
P2P_PORT=30333
RPC_PORT=9944
PROMETHEUS_PORT=9615
MINER_PORT=9833

# Sync settings
SYNC_MODE=full
MAX_BLOCKS_PER_REQUEST=64

# External miner settings
ENABLE_EXTERNAL_MINER=true
CPU_WORKERS=4
GPU_DEVICES=0
```

## Node Management

### Service Commands

```bash
# Start the node
systemctl start quantus-node

# Stop the node
systemctl stop quantus-node

# Restart
systemctl restart quantus-node

# Check status
systemctl status quantus-node

# View logs
journalctl -u quantus-node -f
```

### StratumOS Integration Commands

```bash
# Via stratum command
stratum --action=start :quantus-node
stratum --action=stop :quantus-node
stratum --action=status :quantus-node
stratum --action=restart :quantus-node
```

## Mining Setup

### 1. Generate Wormhole Address

```bash
# Generate a new wormhole keypair
/opt/quantus-node/scripts/generate-keys.sh

# Or use the node binary directly
/opt/quantus-node/bin/quantus-node key quantus --scheme wormhole
```

Save the `inner_hash` value — this is your mining preimage.

### 2. Configure Rewards

Edit `/opt/quantus-node/config` and set:

```bash
INNER_HASH="your_inner_hash_here"
```

### 3. Start Mining

```bash
# Start with external miner (recommended)
/opt/quantus-node/update --start

# Start node only (no mining)
/opt/quantus-node/update --start-node-only
```

### 4. Start External Miner (Optional)

```bash
# In a separate terminal
/opt/quantus-node/bin/quantus-miner serve \
  --cpu-workers 4 \
  --gpu-devices 0 \
  --node-addr 127.0.0.1:9833 \
  --auth-token-file /opt/quantus-node/data/chains/mainnet/miner-auth-token \
  --tls-cert-sha256-file /opt/quantus-node/data/chains/mainnet/miner-tls-cert-sha256
```

## Monitoring

### Prometheus Metrics

```
http://localhost:9615/metrics
```

### RPC Endpoint

```
http://localhost:9944
```

### Telemetry

Find your node at: https://telemetry.quantus.cat/

### StratumOS Dashboard

Access the web dashboard through your StratumOS panel for:
- Node sync status
- Peer count
- Block height
- Mining status
- Resource usage

## File Locations

| Path | Description |
|------|-------------|
| `/opt/quantus-node/bin/quantus-node` | Node binary |
| `/opt/quantus-node/bin/quantus-miner` | Miner binary |
| `/opt/quantus-node/config` | Configuration file |
| `/opt/quantus-node/data/` | Node data directory |
| `/opt/quantus-node/data/chains/mainnet/` | Chain data |
| `/opt/quantus-node/data/chains/mainnet/miner-auth-token` | Miner auth token |
| `/opt/quantus-node/data/chains/mainnet/miner-tls-cert-sha256` | TLS cert fingerprint |
| `/opt/quantus-node/logs/` | Log files |
| `/etc/systemd/system/quantus-node.service` | Service file |

## Updating

```bash
# Update to latest version
/opt/quantus-node/update

# Or via StratumOS
stratum --action=update :quantus-node
```

## Troubleshooting

### Node won't sync
```bash
# Check logs
journalctl -u quantus-node -n 100

# Check ports
ss -tlnp | grep -E '30333|9944'

# Restart
systemctl restart quantus-node
```

### Mining not working
```bash
# Verify inner hash is set
grep INNER_HASH /opt/quantus-node/config

# Check miner connection
ss -ulnp | grep 9833

# View miner logs
tail -f /opt/quantus-node/logs/miner.log
```

### Reset chain data
```bash
# WARNING: This deletes all chain data
/opt/quantus-node/update --purge
```

## Security

- Only port 30333 (P2P) should be publicly accessible
- Port 9833 (miner) must stay private — use firewall rules
- Port 9944 (RPC) and 9615 (metrics) should be firewalled
- Keep `miner-auth-token` secure — treat it like a password
- Backup your wormhole seed phrase — it controls your rewards

## License

MIT — See [Quantus Network](https://github.com/Quantus-Network/chain) for node license.
