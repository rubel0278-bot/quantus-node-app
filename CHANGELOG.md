# Changelog

## [1.0.0] - 2026-10-02

### Added
- Initial release of Quantus Network Node for StratumOS
- Support for mainnet and heisenberg testnet chains
- Automatic binary download from official GitHub releases
- Wormhole address generation for mining rewards
- External miner support via QUIC protocol
- Systemd service integration for auto-start and restart
- StratumOS web dashboard for remote monitoring
- Prometheus metrics endpoint
- Firewall configuration (UFW and firewalld)
- Key generation helper scripts
- Update management script

### Features
- **Node Management**: Start, stop, restart, status, logs
- **Mining**: QPoW mining with external miner support
- **Monitoring**: Prometheus metrics, RPC queries, web dashboard
- **Security**: Firewall rules, miner auth token, TLS cert pinning
- **StratumOS Integration**: Desktop entries, menu integration, web panel

### Supported Platforms
- Linux x86_64 (Ubuntu, Debian, CentOS, Fedora)
- Linux ARM64 (ARMv8)

### Requirements
- 2+ CPU cores
- 4GB+ RAM
- 100GB+ storage
- Stable internet connection (3+ Mbps)
