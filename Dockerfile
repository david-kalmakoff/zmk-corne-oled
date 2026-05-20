# ZMK Local Build Environment
# Replicates the GitHub Actions build-user-config workflow for local use.
#
# USAGE:
#   docker build -t zmk-build .
#   docker run --rm -v "$(pwd)":/workspace zmk-build
#
# The built firmware (.uf2 files) will appear in the ./output/ directory.

FROM docker.io/zmkfirmware/zmk-build-arm:stable

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl jq python3-yaml && \
    YQ_ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/v4.45.4/yq_linux_${YQ_ARCH}" \
        -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq && \
    rm -rf /var/lib/apt/lists/*

COPY build-local.sh /usr/local/bin/build-local.sh
RUN chmod +x /usr/local/bin/build-local.sh

ENTRYPOINT ["/usr/local/bin/build-local.sh"]
