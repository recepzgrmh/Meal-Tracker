#!/usr/bin/env bash
# Run the paid live eval against the hosted project.
#
# The runner needs a user JWT, and those expire after an hour, so the usual
# failure is a run whose cases all report "401" — that is the Supabase gateway
# rejecting the token, not the model provider. This script mints a fresh token
# on every run so the token is never the variable under test.
#
# Usage:
#   export SUPABASE_SERVICE_ROLE_KEY=...      # required, never committed
#   tool/eval/run_live_eval.sh                       # 20 bilingual text cases
#   tool/eval/run_live_eval.sh evals/gold/photo_meals_v1.json 4
#
# SUPABASE_URL and the publishable key are read from config/app_config.dev.json
# unless already exported.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
dataset="${1:-evals/gold/bilingual_hybrid_v1.jsonl}"
max_cases="${2:-20}"
eval_email="${EVAL_USER_EMAIL:-eval@test.com}"
config="$repo_root/config/app_config.dev.json"

if [[ -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
  echo "SUPABASE_SERVICE_ROLE_KEY is required (Project Settings -> API)." >&2
  exit 1
fi

read_config() {
  [[ -f "$config" ]] || return 1
  python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get(sys.argv[2],''))" \
    "$config" "$1"
}

supabase_url="${SUPABASE_URL:-$(read_config SUPABASE_URL || true)}"
publishable_key="${SUPABASE_PUBLISHABLE_KEY:-$(read_config SUPABASE_PUBLISHABLE_KEY || true)}"
supabase_url="${supabase_url%/}"

if [[ -z "$supabase_url" || -z "$publishable_key" ]]; then
  echo "Set SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY, or provide $config." >&2
  exit 1
fi

# An admin magic link avoids needing the eval account's password, and verifying
# it immediately exchanges the hash for a session without sending mail.
echo "Minting a fresh token for $eval_email ..." >&2
token_hash="$(
  curl -fsS -X POST "$supabase_url/auth/v1/admin/generate_link" \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    -H 'Content-Type: application/json' \
    -d "{\"type\":\"magiclink\",\"email\":\"$eval_email\"}" |
    python3 -c 'import json,sys; print(json.load(sys.stdin).get("hashed_token",""))'
)"

if [[ -z "$token_hash" ]]; then
  echo "Could not generate a login link. Check the service-role key and that" >&2
  echo "$eval_email exists and is confirmed in Authentication -> Users." >&2
  exit 1
fi

user_jwt="$(
  curl -fsS -X POST "$supabase_url/auth/v1/verify" \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H 'Content-Type: application/json' \
    -d "{\"type\":\"magiclink\",\"token_hash\":\"$token_hash\"}" |
    python3 -c 'import json,sys; print(json.load(sys.stdin).get("access_token",""))'
)"

if [[ -z "$user_jwt" ]]; then
  echo "Login link could not be exchanged for a session." >&2
  exit 1
fi

echo "Running $dataset (max $max_cases cases) ..." >&2
cd "$repo_root/supabase"
EVAL_SUPABASE_URL="$supabase_url" \
EVAL_SUPABASE_PUBLISHABLE_KEY="$publishable_key" \
EVAL_USER_JWT="$user_jwt" \
LIVE_EVAL_ACK=I_ACCEPT_PROVIDER_COST \
EVAL_MAX_CASES="$max_cases" \
SUPABASE_SERVICE_ROLE_KEY="$SUPABASE_SERVICE_ROLE_KEY" \
  deno task eval:live "$dataset" --persist
