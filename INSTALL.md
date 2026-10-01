# Quantus Network Node — StratumOS Installation Guide

## Quick Install

```bash
# Clone this repository
git clone https://github.com/YOUR_USERNAME/quantus-node-app.git /tmp/quantus-node-app
cd /tmp/quantus-node-app

# Run the installer
sudo ./install.sh --full
```

## What Gets Installed

| Component | Location |
|-----------|----------|
| Node binary | `/opt/quantus-node/bin/quantus-node` |
| Miner binary | `/opt/quantus-node/bin/quantus-miner` |
| Configuration | `/opt/quantus-node/config` |
| Data directory | `/opt/quantus-node/data/` |
| Logs | `/opt/quantus-node/logs/` |
| Service | `/etc/systemd/system/quantus-node.service` |
| Dashboard | `http://localhost:8080` |

## Post-Install Steps

1. **Set your wormhole inner hash:**

```bash
# Generate a new wormhole keypair
/opt/quantus-node/scripts/generate-keys.sh

# Or use an existing one
nano /opt/quantus-node/config
# Set INNER_HASH="your_inner_hash_here"
```

2. **Start the node:**

```bash
systemctl start quantus-node
```

3. **Check status:**

```bash
/opt/quantus-node/update --status
```

4. **View logs:**

```bash
journalctl -u quantus-node -f
```

## StratumOS App Store Publishing

To publish this app to the StratumOS app store:

1. Push this repository to GitHub
2. Add the `app.json` manifest (already included)
3. Submit to the StratumOS app registry

## Updating

```bash
# Update binaries
/opt/quantus-node/update --update

# Or via the app
cd /opt/quantus-node
./update --update
```

## Uninstalling

```bash
/opt/quantus-node/update --uninstall
```

## Troubleshooting

### Node won't start
```bash
# Check logs
journalctl -u quantus-node -n 50

# Check config
cat /opt/quantus-node/config

# Check ports
ss -tlnp | grep -E '30333|9944'
```

### Mining not working
```bash
# Verify inner hash
grep INNER_HASH /opt/quantus-node/config

# Check miner process
pgrep -f quantus-miner

# Check miner port
ss -ulnp | grep 9833
```

### Reset everything
```bash
# Stop node
systemctl stop quantus-node

# Delete data
rm -rf /opt/quantus-node/data/chains/*

# Start fresh
systemctl start quantus-node
```
