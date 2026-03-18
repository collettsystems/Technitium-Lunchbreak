#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/technitium-common.sh"

require_cmd
count=0

while IFS= read -r domain; do
  [[ -z "$domain" ]] && continue

  if [[ "$REMOVE_FROM_ALLOWED_ON_BLOCK" == "1" ]]; then
    if ! disallow_domain "$domain"; then
      log "warning: could not remove from allowed: $domain"
    fi
  fi

  block_domain "$domain"
  count=$((count + 1))
done < <(iter_domains)

log "done: blocked $count domain(s) from $DOMAIN_LIST"
