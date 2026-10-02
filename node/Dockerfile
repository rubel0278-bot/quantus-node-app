FROM ubuntu:24.04

LABEL org.opencontainers.image.source="https://github.com/rubel0278-bot/quantus-node-app"
LABEL org.opencontainers.image.description="Quantus Network Node v1.0.2-Qm - blockchain node with built-in solo mining"

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
 && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH=amd64
ARG QUANTUS_VERSION=v1.0.2-Qm
ARG QUANTUS_ARCH=x86_64-unknown-linux-gnu
ARG QUANTUS_SHA256=c0fb354772f4637c6db3a5e701ae8c4a6fc44c5414a38f1a95b91bc13b1e9063

RUN if [ "${TARGETARCH}" != "amd64" ]; then \
      echo "Only linux/amd64 is supported for the pinned v1.0.2-Qm artifact"; \
      exit 1; \
    fi \
 && curl -fSL -o /tmp/quantus-node.tar.gz \
    "https://github.com/Quantus-Network/chain/releases/download/${QUANTUS_VERSION}/quantus-node-${QUANTUS_VERSION}-${QUANTUS_ARCH}.tar.gz" \
 && echo "${QUANTUS_SHA256}  /tmp/quantus-node.tar.gz" | sha256sum -c - \
 && tar -xzf /tmp/quantus-node.tar.gz -C /usr/local/bin/ \
 && rm /tmp/quantus-node.tar.gz \
 && chmod +x /usr/local/bin/quantus-node

RUN useradd --system --uid 10001 quantus \
 && mkdir -p /data \
 && chown 10001:10001 /data

USER 10001:10001

EXPOSE 30333 9944 9615

COPY --chmod=0755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
