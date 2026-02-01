#!/bin/bash
# Standalone script to fetch F2P server tokens and start Hytale server
# Place in same directory as HytaleServer.jar and Assets.zip
# Usage: ./run_server_with_tokens.sh [additional server args...]

set -e

# Configuration (edit these if needed)
# Domain for F2P auth server (default: auth.sanasol.ws)
# F2P always uses single endpoint without subdomains: https://{domain}
HYTALE_AUTH_DOMAIN="${HYTALE_AUTH_DOMAIN:-auth.sanasol.ws}"
AUTH_SERVER="${AUTH_SERVER:-https://${HYTALE_AUTH_DOMAIN}}"
SERVER_NAME="${SERVER_NAME:-My Hytale Server}"
ASSETS_PATH="${ASSETS_PATH:-./Assets.zip}"
BIND_ADDRESS="${BIND_ADDRESS:-0.0.0.0:5520}"
AUTH_MODE="${AUTH_MODE:-authenticated}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Check for required files
if [ ! -f "HytaleServer.jar" ]; then
    error "HytaleServer.jar not found in current directory"
    error "Please run this script from the directory containing HytaleServer.jar"
    exit 1
fi

if [ ! -f "${ASSETS_PATH}" ]; then
    error "Assets.zip not found at: ${ASSETS_PATH}"
    error "Please ensure Assets.zip is in the current directory or set ASSETS_PATH"
    exit 1
fi

# Check for curl
if ! command -v curl &> /dev/null; then
    error "curl is required but not installed"
    exit 1
fi

# Check for java
if ! command -v java &> /dev/null; then
    error "java is required but not installed"
    exit 1
fi

# Generate or load server ID
SERVER_ID_FILE=".server-id"
if [ -f "${SERVER_ID_FILE}" ]; then
    SERVER_ID=$(cat "${SERVER_ID_FILE}")
    log "Using existing server ID: ${SERVER_ID}"
else
    if command -v uuidgen &> /dev/null; then
        SERVER_ID=$(uuidgen)
    elif [ -f /proc/sys/kernel/random/uuid ]; then
        SERVER_ID=$(cat /proc/sys/kernel/random/uuid)
    else
        SERVER_ID="server-$(hostname)-$(date +%s)"
    fi
    echo -n "${SERVER_ID}" > "${SERVER_ID_FILE}"
    log "Generated new server ID: ${SERVER_ID}"
fi

log "Fetching server tokens from ${AUTH_SERVER}..."
log "  Server ID: ${SERVER_ID}"
log "  Server Name: ${SERVER_NAME}"

# Fetch tokens from auth server
RESPONSE=$(curl -s -X POST "${AUTH_SERVER}/server/auto-auth" \
    -H "Content-Type: application/json" \
    -d "{\"server_id\": \"${SERVER_ID}\", \"server_name\": \"${SERVER_NAME}\"}" \
    --connect-timeout 10 \
    --max-time 30 2>/dev/null) || {
    error "Failed to connect to auth server at ${AUTH_SERVER}"
    exit 1
}

# Check for valid response
if ! echo "${RESPONSE}" | grep -q "sessionToken"; then
    error "Invalid response from auth server:"
    echo "${RESPONSE}"
    exit 1
fi

# Extract tokens (compatible with both GNU and BSD sed)
SESSION_TOKEN=$(echo "${RESPONSE}" | sed -n 's/.*"sessionToken"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
IDENTITY_TOKEN=$(echo "${RESPONSE}" | sed -n 's/.*"identityToken"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

if [ -z "${SESSION_TOKEN}" ] || [ -z "${IDENTITY_TOKEN}" ]; then
    error "Could not extract tokens from response"
    echo "${RESPONSE}"
    exit 1
fi

log "Successfully fetched server tokens"
log "  Session token: [set]"
log "  Identity token: [set]"

# Build java command
JAVA_ARGS=""
if [ -n "${JVM_XMS:-}" ]; then
    JAVA_ARGS="${JAVA_ARGS} -Xms${JVM_XMS}"
fi
if [ -n "${JVM_XMX:-}" ]; then
    JAVA_ARGS="${JAVA_ARGS} -Xmx${JVM_XMX}"
fi

log ""
log "Starting Hytale Server..."
log "  Assets: ${ASSETS_PATH}"
log "  Bind: ${BIND_ADDRESS}"
log "  Auth mode: ${AUTH_MODE}"
log ""

# Start the server
exec java ${JAVA_ARGS} -jar HytaleServer.jar \
    --assets "${ASSETS_PATH}" \
    --bind "${BIND_ADDRESS}" \
    --auth-mode "${AUTH_MODE}" \
    --session-token "${SESSION_TOKEN}" \
    --identity-token "${IDENTITY_TOKEN}" \
    "$@"
