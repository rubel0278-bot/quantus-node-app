# Quantus Network Node — StratumOS Application

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/Quantus-Network/chain/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20x86__64%20%7C%20ARM64-orange.svg)](https://stratumos.com)

A complete [StratumOS](https://stratumos.com) application for running a [Quantus Network](https://quantus.network) node with QPoW mining support.

## Features

- **One-command installation** — downloads and configures everything
- **Mainnet & testnet support** — `mainnet` and `heisenberg` chains
- **Wormhole address generation** — for privacy-preserving mining rewards
- **External miner support** — QUIC-based miner protocol
- **Systemd integration** — auto-start, restart on failure
- **Web dashboard** — monitor your node from the StratumOS panel
- **Prometheus metrics** — detailed node metrics
- **Firewall auto-configuration** — UFW and firewalld support

## Quick Start

```bash
# Clone and install
git clone https://github.com/YOUR_USERNAME/quantus-node-app.git
cd quantus-node-app
sudo ./install.sh --full

# Set your wormhole inner hash
sudo nano /opt/quantus-node/config

# Start mining
sudo systemctl start quantus-node

# Check status
/opt/quantus-node/update --status
```

## Documentation

- [Installation Guide](INSTALL.md)
- [Configuration](config)
- [Changelog](CHANGELOG.md)

## StratumOS Integration

This app follows the StratumOS app format:

```
/opt/quantus-node/
├── install.sh          # Main installer
├── update              # Update & management script
├── config              # Configuration file
├── quantus-node        # Entry point script
├── stratum-init.sh     # StratumOS init script
├── windows-init        # Desktop integration
├── chrome-init         # Browser integration
├── menu-init           # Menu integration
├── service/
│   └── quantus-node.service
├── scripts/
│   ├── setup-node.sh
│   ├── generate-keys.sh
│   └── monitor.sh
└── www/
    ├── index.html      # Web dashboard
    └── server.py       # Dashboard API
```

## License

MIT — See [Quantus Network](https://github.com/Quantus-Network/chain) for node license.
