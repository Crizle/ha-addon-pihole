# syntax=docker/dockerfile:1
# ─────────────────────────────────────────────────────────────────────────────
# Pi-hole Home Assistant Add-on
# ─────────────────────────────────────────────────────────────────────────────
ARG BUILD_FROM="pihole/pihole:latest"
FROM ${BUILD_FROM}

ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

LABEL \
    io.hass.name="Pi-hole" \
    io.hass.description="Network-wide ad blocking via DNS" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}"

# Ensure we run as root so we can bind port 53 and manage /etc/pihole
USER root

# ── Install bashio ────────────────────────────────────────────────────────────
ARG BASHIO_VERSION="0.16.2"
RUN apk add --no-cache curl bash jq nginx \
    && curl -fsSL -o /tmp/bashio.tar.gz \
        "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf /tmp/bashio.tar.gz --strip 1 -C /tmp/bashio \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -sf /usr/lib/bashio/bashio.sh /usr/bin/bashio \
    && rm -rf /tmp/bashio /tmp/bashio.tar.gz

# ── Add our startup wrapper ───────────────────────────────────────────────────
COPY run.sh /run.sh
COPY nginx.conf.tmpl /etc/nginx/nginx.conf.tmpl
RUN chmod +x /run.sh

# Override Pi-hole's default ENTRYPOINT (start.sh) with our wrapper.
# Our wrapper sets FTLCONF_* env vars then execs /usr/bin/start.sh.
ENTRYPOINT ["/bin/bash", "/run.sh"]
