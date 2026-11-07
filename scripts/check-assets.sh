#!/usr/bin/env bash
# Check that every asset index.html references is served with HTTP 200.
# Usage: scripts/check-assets.sh [base-url]   (default https://linesterminal.com)
# Run after every deploy. Exits non-zero if anything is not 200.
set -uo pipefail
BASE="${1:-https://linesterminal.com}"; BASE="${BASE%/}"
HTML="$(dirname "$0")/../index.html"

# 1. Wait until the live page IS this index.html. Right after a deploy the old
#    container keeps serving for a minute or two, which would make the asset
#    check pass or fail against the wrong version.
#    Cloudflare's Email Address Obfuscation rewrites the mailto link and
#    injects a decoder <script>, so drop those before comparing.
norm() { tr -d '\r' | sed -E -e 's#<script data-cfasync="false" src="/cdn-cgi/[^"]*"></script>##g' \
                              -e '/mailto:|__cf_email__|email-protection/d' | sha256sum | cut -d' ' -f1; }
want=$(norm < "$HTML")
for i in $(seq 1 "${WAIT_TRIES:-24}"); do
  ok=1
  for j in 1 2 3 4 5; do   # several requests, since two containers may alternate
    got=$(curl -s --max-time 20 -H 'Cache-Control: no-cache' "$BASE/?check=$RANDOM$j" | norm)
    [ "$got" = "$want" ] || { ok=0; break; }
  done
  [ "$ok" = 1 ] && { echo "live index.html matches local copy"; break; }
  [ "$i" = "${WAIT_TRIES:-24}" ] && { echo "FAIL live index.html still differs from local copy after $i tries"; exit 1; }
  echo "waiting for deploy to settle ($i)..."; sleep 10
done

# 2. Every referenced asset must be 200.
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
