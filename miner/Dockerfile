FROM ubuntu:24.04

LABEL org.opencontainers.image.source="https://github.com/rubel0278-bot/quantus-node-app"
LABEL org.opencontainers.image.description="Quantus Network Miner v4.2.0 - external solo mining service"

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fSL -o /usr/local/bin/quantus-miner \
    "https://github.com/Quantus-Network/quantus-miner/releases/download/v4.2.0/quantus-miner-linux-x86_64" \
 && chmod +x /usr/local/bin/quantus-miner

RUN useradd --system --uid 1000 miner

USER 1000:1000

ENTRYPOINT ["quantus-miner"]
CMD ["serve"]
