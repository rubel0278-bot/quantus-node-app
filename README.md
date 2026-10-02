# Quantus Node — 5tratumOS Application

Node-only 5tratumOS community store application for running a Quantus Network node with the official v1.0.2-Qm binary and built-in solo mining.

## Runtime

- One container service: `node`
- Official binary: `quantus-node-v1.0.2-Qm-x86_64-unknown-linux-gnu.tar.gz`
- SHA256: `c0fb354772f4637c6db3a5e701ae8c4a6fc44c5414a38f1a95b91bc13b1e9063`
- Solo mining is enabled by running the node as a validator without `--miner-listen-port`
- No dashboard container
- No separate `quantus-miner` container

## Ports

| Port | Protocol | Exposure | Purpose |
|------|----------|----------|---------|
| 30333 | TCP | Public | P2P networking |
| 9944 | HTTP | Internal | RPC endpoint |
| 9615 | HTTP | Internal | Prometheus metrics |

## Data Persistence

| Volume | Container Path | Purpose |
|--------|----------------|---------|
| `${APP_DATA_DIR}/data` | `/data` | Chain data, node key, and persisted config |

## Startup

The container entrypoint creates `/data/quantus-node.env` on first start, generates `/data/node_key.p2p` when missing, generates and persists the wormhole `INNER_HASH`, then starts the node with:

```bash
quantus-node \
  --name <node-name> \
  --validator \
  --chain mainnet \
  --base-path /data \
  --node-key-file /data/node_key.p2p \
  --rewards-inner-hash <0x...> \
  --port 30333 \
  --rpc-port 9944 \
  --prometheus-port 9615 \
  --sync full \
  --max-blocks-per-request 64 \
  --rpc-methods safe
```

## Store Submission

This application is designed for submission to `WillItMod/5tratStore-global`.

Required files:
- `5tratstore-app.yml`
- `5tratstore-review.yml`
- `LICENSES.md`
- `docker-compose.yml`
- `icon.png`
