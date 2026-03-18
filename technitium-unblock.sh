#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/technitium-common.sh"

require_cmd
count=0

while IFS= read -r domain; do
  [[ -z "$domain" ]] && continue

  unblock_domain "$domain"

  if [[ "$ADD_TO_ALLOWED_ON_UNBLOCK" == "1" ]]; then
    allow_domain "$domain"
  fi

  count=$((count + 1))
done < <(iter_domains)

log "done: unblocked $count domain(s) from $DOMAIN_LIST"
