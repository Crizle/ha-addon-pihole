#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Pi-hole HA Addon — startup wrapper
#
# Architecture:
#   HA ingress (INGRESS_PORT) → nginx (strips X-Frame-Options) → FTL (9080)
#
# Pi-hole's FTL web server sends X-Frame-Options: DENY which blocks HA's
# ingress iframe. nginx proxies and removes that header so the admin panel
# loads correctly inside the HA sidebar.
# ─────────────────────────────────────────────────────────────────────────────

# shellcheck source=/dev/null
source /usr/lib/bashio/bashio.sh 2>/dev/null || true

# Safe config reader with fallback
read_option() {
    local key="$1" default="$2"
    local val
    val="$(bashio::config "$key" 2>/dev/null)" || val="$default"
    [[ -z "$val" ]] && val="$default"
    echo "$val"
}

# ── Read addon options ────────────────────────────────────────────────────────
UPSTREAM_DNS="$(read_option 'upstream_dns'     '1.1.1.1;8.8.8.8')"
TZ_CONF="$(read_option      'timezone'         'Europe/London')"
DNSSEC="$(read_option       'dnssec'           'false')"
LISTENING_MODE="$(read_option 'listening_mode' 'all')"
BLOCKING="$(read_option     'blocking_enabled' 'true')"
QUERY_LOG="$(read_option    'query_logging'    'true')"

# ── Ports ─────────────────────────────────────────────────────────────────────
# INGRESS_PORT  — HA-assigned external port (proxied by HA ingress iframe)
# PIHOLE_PORT   — internal port FTL listens on (not directly accessible)
PIHOLE_PORT=9080

INGRESS_PORT=""
INGRESS_PORT="$(bashio::addon.ingress_port 2>/dev/null)" || INGRESS_PORT=""
if [[ -z "$INGRESS_PORT" || "$INGRESS_PORT" == "null" ]]; then
    bashio::log.warning "Could not read ingress port — using fallback 8099"
    INGRESS_PORT="8099"
fi

INGRESS_ENTRY=""
INGRESS_ENTRY="$(bashio::addon.ingress_entry 2>/dev/null)" || INGRESS_ENTRY=""
[[ "$INGRESS_ENTRY" == "null" ]] && INGRESS_ENTRY=""

bashio::log.info "Ingress port : ${INGRESS_PORT} (nginx)"
bashio::log.info "Ingress entry: ${INGRESS_ENTRY}"
bashio::log.info "FTL port     : ${PIHOLE_PORT} (internal)"

# ── Persistent storage ────────────────────────────────────────────────────────
mkdir -p /data/pihole 2>/dev/null || true

if [[ -d /etc/pihole && ! -L /etc/pihole ]]; then
    cp -rn /etc/pihole/. /data/pihole/ 2>/dev/null || true
    rm -rf /etc/pihole
    ln -sf /data/pihole /etc/pihole
elif [[ ! -e /etc/pihole ]]; then
    ln -sf /data/pihole /etc/pihole
fi

# ── nginx — proxy with X-Frame-Options header stripped ───────────────────────
bashio::log.info "Starting nginx proxy..."

# Ensure nginx proxy temp dir exists and is writable (needed for proxy_buffering
# and sub_filter; if missing, nginx silently disables buffering and sub_filter
# stops working even with proxy_buffering on).
mkdir -p /var/lib/nginx/tmp/proxy 2>/dev/null || true
chown -R nginx:nginx /var/lib/nginx/tmp 2>/dev/null || true

sed \
    -e "s/INGRESS_PORT_PLACEHOLDER/${INGRESS_PORT}/g" \
    -e "s/PIHOLE_PORT_PLACEHOLDER/${PIHOLE_PORT}/g" \
    -e "s|INGRESS_ENTRY_PLACEHOLDER|${INGRESS_ENTRY}|g" \
    /etc/nginx/nginx.conf.tmpl > /etc/nginx/nginx.conf

nginx || bashio::log.warning "nginx failed to start — admin panel may not load in HA sidebar"

# ── Pi-hole FTLCONF_* environment variables ───────────────────────────────────
bashio::log.info "Configuring Pi-hole FTL..."

export FTLCONF_webserver_port="${PIHOLE_PORT}"       # internal only — nginx fronts it

# DNS rebinding protection: FTL rejects requests whose Host header doesn't
# match webserver.domain. Since nginx sends Host: localhost, set domain to match.
export FTLCONF_webserver_domain="localhost"

# Disable Pi-hole's own web authentication.
# Access is already controlled by HA's login — anyone reaching this addon via
# the HA ingress has already authenticated with Home Assistant. Pi-hole's session
# cookies use domain=localhost which doesn't survive the ingress reverse proxy,
# so enabling Pi-hole auth just produces a /login redirect loop.
#
# WEBPASSWORD="" prevents the startup script from assigning a random password
# (which causes log noise).  FTLCONF_webserver_api_password="" is the FTL v6
# override that actually disables authentication at the API/Lua layer.
export WEBPASSWORD=""
export FTLCONF_webserver_api_password=""

# webroot is the filesystem base; webhome is the URL prefix FTL serves from.
# Pi-hole assets live in /var/www/html/admin/, referenced in HTML as /admin/assets/...
# So webroot=/var/www/html and webhome=/admin/ gives correct path resolution.
export FTLCONF_webserver_paths_webroot="/var/www/html"
export FTLCONF_webserver_paths_webhome="/admin/"

export FTLCONF_dns_upstreams="${UPSTREAM_DNS}"
export FTLCONF_dns_listeningMode="${LISTENING_MODE}"
export FTLCONF_dns_dnssec="${DNSSEC}"
export TZ="${TZ_CONF}"

# Remove stale config so FTLCONF_* vars always win on fresh start
rm -f /etc/pihole/pihole.toml 2>/dev/null || true

if [[ "${BLOCKING}" == "true" ]]; then
    export FTLCONF_dns_blocking_mode="NULL"
else
    export FTLCONF_dns_blocking_mode="NXDOMAIN"
fi

if [[ "${QUERY_LOG}" == "true" ]]; then
    export FTLCONF_misc_privacylevel="0"
else
    export FTLCONF_misc_privacylevel="3"
fi

bashio::log.info "Starting Pi-hole (FTL v6)..."
bashio::log.info "  DNS      : port 53"
bashio::log.info "  Web (FTL): port ${PIHOLE_PORT} (internal)"
bashio::log.info "  Web (HA) : port ${INGRESS_PORT} via nginx"

# ── Hand off to Pi-hole ───────────────────────────────────────────────────────
exec /usr/bin/start.sh
