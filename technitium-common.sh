#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$SCRIPT_DIR/config.env}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Missing config file: $CONFIG_FILE" >&2
  echo "Copy $SCRIPT_DIR/config.example.env to $SCRIPT_DIR/config.env and edit it." >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

: "${TECHNITIUM_URL:?TECHNITIUM_URL is required}"
: "${TECHNITIUM_TOKEN:?TECHNITIUM_TOKEN is required}"
: "${DOMAIN_LIST:?DOMAIN_LIST is required}"

CURL_TIMEOUT="${CURL_TIMEOUT:-30}"
LOG_FILE="${LOG_FILE:-}"
TECHNITIUM_NODE="${TECHNITIUM_NODE:-}"
REMOVE_FROM_ALLOWED_ON_BLOCK="${REMOVE_FROM_ALLOWED_ON_BLOCK:-0}"
ADD_TO_ALLOWED_ON_UNBLOCK="${ADD_TO_ALLOWED_ON_UNBLOCK:-0}"

log() {
  local msg ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  msg="[$ts] $*"
  echo "$msg"
  if [[ -n "$LOG_FILE" ]]; then
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$msg" >> "$LOG_FILE"
  fi
}

require_cmd() {
  local cmd
  for cmd in curl; do
    command -v "$cmd" >/dev/null 2>&1 || {
      echo "Required command not found: $cmd" >&2
      exit 1
    }
  done

  if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    echo "Need either jq or python3 to parse API responses." >&2
    exit 1
  fi
}

json_get() {
  local key="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -r "$key"
  else
    python3 - "$key" <<'PY'
import json, sys
expr = sys.argv[1]
data = json.load(sys.stdin)
# tiny dotted-key reader for our limited usage
if expr == '.status':
    print(data.get('status', ''))
elif expr == '.errorMessage':
    print(data.get('errorMessage', ''))
else:
    raise SystemExit(f'Unsupported expression: {expr}')
PY
  fi
}

api_call() {
  local endpoint="$1"
  shift || true

  local url response curl_args=()
  url="${TECHNITIUM_URL%/}${endpoint}"

  curl_args+=(--silent --show-error --fail)
  curl_args+=(--max-time "$CURL_TIMEOUT")
  curl_args+=(--request POST)
  curl_args+=(--header 'Content-Type: application/x-www-form-urlencoded')
  curl_args+=(--data-urlencode "token=$TECHNITIUM_TOKEN")

  if [[ -n "$TECHNITIUM_NODE" ]]; then
    curl_args+=(--data-urlencode "node=$TECHNITIUM_NODE")
  fi

  while (($#)); do
    curl_args+=(--data-urlencode "$1")
    shift
  done

  response="$(curl "${curl_args[@]}" "$url")"

  local status
  status="$(printf '%s' "$response" | json_get '.status')"
  if [[ "$status" != "ok" ]]; then
    local err
    err="$(printf '%s' "$response" | json_get '.errorMessage' 2>/dev/null || true)"
    echo "API call failed: ${endpoint} :: ${err:-unknown error}" >&2
    echo "$response" >&2
    return 1
  fi

  printf '%s' "$response"
}

iter_domains() {
  if [[ ! -f "$DOMAIN_LIST" ]]; then
    echo "Domain list not found: $DOMAIN_LIST" >&2
    exit 1
  fi

  awk '
    {
      sub(/\r$/, "")
      if ($0 ~ /^[[:space:]]*#/) next
      if ($0 ~ /^[[:space:]]*$/) next
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      print tolower($0)
    }
  ' "$DOMAIN_LIST"
}

block_domain() {
  local domain="$1"
  api_call '/api/blocked/add' "domain=$domain" >/dev/null
  log "blocked: $domain"
}

unblock_domain() {
  local domain="$1"
  api_call '/api/blocked/delete' "domain=$domain" >/dev/null
  log "unblocked: $domain"
}

allow_domain() {
  local domain="$1"
  api_call '/api/allowed/add' "domain=$domain" >/dev/null
  log "allowed: $domain"
}

disallow_domain() {
  local domain="$1"
  api_call '/api/allowed/delete' "domain=$domain" >/dev/null
  log "removed from allowed: $domain"
}
