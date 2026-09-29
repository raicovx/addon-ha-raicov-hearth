#!/usr/bin/with-contenv bashio

# the server proxies /api/ and /local/ to Home Assistant; on the supervisor
# network it answers to its own hostname
export HASS_URL="http://homeassistant:$(bashio::core.port)"
# Ingress uses the browser's HA origin. Direct access needs a URL the
# browser can reach, independently of the internal server proxy target.
export HASS_PUBLIC_URL=""
if bashio::config.has_value 'hass_public_url'; then
    HASS_PUBLIC_URL="$(bashio::config 'hass_public_url')"
fi

export EXPOSED_PORT=$(bashio::addon.port "8099/tcp")

# optional HTTPS on 8443, beside the plain port Ingress keeps using
if bashio::config.true 'ssl'; then
    bashio::config.require.ssl
    export SSL_CERTFILE="/ssl/$(bashio::config 'certfile')"
    export SSL_KEYFILE="/ssl/$(bashio::config 'keyfile')"
    export SSL_PORT=8443
fi

echo "Starting Hearth..."

node server.js
