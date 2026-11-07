#!/usr/bin/env bash
# Check that every asset index.html references is served with HTTP 200.
# Usage: scripts/check-assets.sh [base-url]   (default https://linesterminal.com)
# Run after every deploy. Exits non-zero if anything is not 200.
set -uo pipefail
BASE="${1:-https://linesterminal.com}"; BASE="${BASE%/}"
HTML="$(dirname "$0")/../index.html"

paths=$(
  {
    # local src / href values (skip in-page anchors and external links)
    grep -oE '(src|href)="/[^"#]*"' "$HTML" | sed -E 's/^[a-z]+="(.*)"$/\1/'
    # srcset: every candidate URL, descriptors dropped
    grep -oE 'srcset="[^"]*"' "$HTML" | sed -E 's/^srcset="(.*)"$/\1/' | tr ',' '\n' | awk '{print $1}'
    # absolute URLs on our own domain (og:image, twitter:image, canonical)
    grep -oE '"https://linesterminal\.com/[^"]*"' "$HTML" | tr -d '"' | sed -E 's#^https://linesterminal\.com##'
    echo /health
  } | grep -E '^/' | sort -u
)

fail=0; n=0
for p in $paths; do
  n=$((n+1))
  read -r code ctype <<<"$(curl -s -o /dev/null -w '%{http_code} %{content_type}' --max-time 20 "$BASE$p")"
  if [ "$code" = "200" ]; then printf 'ok   %s  %s\n' "$p" "$ctype"
  else printf 'FAIL %s  HTTP %s\n' "$p" "$code"; fail=$((fail+1)); fi
done
echo "$n checked, $fail failed against $BASE"
[ "$fail" -eq 0 ]
