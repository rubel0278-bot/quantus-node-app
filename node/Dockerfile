FROM ubuntu:24.04

LABEL org.opencontainers.image.source="https://github.com/rubel0278-bot/quantus-node-app"
LABEL org.opencontainers.image.description="Quantus Network Node v1.0.2-Qm - blockchain node with miner QUIC server"

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
 && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH
RUN curl -fSL -o /tmp/quantus-node.tar.gz \
    "https://github.com/Quantus-Network/chain/releases/download/v1.0.2-Qm/quantus-node-v1.0.2-Qm-${TARGETARCH}-unknown-linux-gnu.tar.gz" \
 && tar -xzf /tmp/quantus-node.tar.gz -C /usr/local/bin/ \
 && rm /tmp/quantus-node.tar.gz \
 && chmod +x /usr/local/bin/quantus-node

RUN useradd --system --uid 10001 quantus

USER 10001:10001

EXPOSE 30333 9944 9833/udp

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
