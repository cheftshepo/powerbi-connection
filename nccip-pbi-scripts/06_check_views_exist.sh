#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.env"
source "$(dirname "$0")/lib_sp.sh"
load_sp_creds

SP_DISPLAY_NAME=$(az ad sp show --id "$SP_CLIENT_ID" --query displayName -o tsv)
TOKEN_FILE="$(dirname "$0")/pbi_pg_token.txt"

if [ ! -f "$TOKEN_FILE" ]; then
  echo "No token found — run 03_get_pbi_token.sh first."
  exit 1
fi

echo "== Checking which Page-1 views exist in nccip_db =="
PGPASSWORD=$(cat "$TOKEN_FILE") psql \
  -h "$PG_HOST" -U "$SP_DISPLAY_NAME" -d "$PG_DB_NAME" --set=sslmode=require \
  -c "SELECT table_name FROM information_schema.views
      WHERE table_schema = 'public'
      AND table_name IN ('v_posts_with_geo','v_sentiment_trend','v_escalations','v_pending_responses');"

echo ""
echo "Run this BEFORE building Page 1. If rows are missing here, you'll need"
echo "to either create the view or point the visuals at base tables"
echo "(enriched_posts etc.) instead — better to know now than live tomorrow."
