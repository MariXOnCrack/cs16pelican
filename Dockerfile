# Pelican/Pterodactyl-compatible wrapper around the stock cs16-web-server image.
# Wings never overrides ENTRYPOINT/CMD, so the egg's startup command is only
# honoured if the image itself evaluates $STARTUP (see entrypoint.sh).
FROM --platform=linux/386 ghcr.io/balintsoos/cs16-web-server:latest

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl tini \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -d /home/container -s /bin/bash container

# Game files live in the server volume (/home/container), copied there by the egg's install script.
ENV HOME=/home/container USER=container \
    XASH3D_BASEDIR=/home/container LD_LIBRARY_PATH=/home/container

USER container
WORKDIR /home/container
COPY --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/bin/bash", "/entrypoint.sh"]
CMD []
