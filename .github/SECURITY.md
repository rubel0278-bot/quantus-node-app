# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in the Quantus Node StratumOS application, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

Instead, please report vulnerabilities by:

1. Opening a [private security advisory](https://github.com/YOUR_USERNAME/quantus-node-app/security/advisories/new) on GitHub
2. Or emailing the maintainers directly

Please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will acknowledge receipt within 48 hours and aim to provide a fix or mitigation within 7 days.

## Security Considerations for Users

When running a Quantus node:

- **Firewall**: Only port 30333 (P2P) should be publicly accessible
- **Miner port**: Port 9833 (UDP) must stay private — never expose to the internet
- **RPC port**: Port 9944 should be firewalled to localhost only
- **Miner auth token**: Treat `miner-auth-token` like a password
- **Seed phrase**: Backup your 24-word wormhole seed phrase — it controls your mining rewards
- **Updates**: Keep your node binary updated to the latest version
