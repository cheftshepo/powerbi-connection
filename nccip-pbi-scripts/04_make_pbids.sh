#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.env"

OUT="$(dirname "$0")/nccip_dashboard.pbids"
cat > "$OUT" <<EOF
{
  "version": "0.1",
  "connections": [
    {
      "details": {
        "protocol": "postgresql",
        "address": {
          "server": "$PG_HOST",
          "database": "$PG_DB_NAME"
        }
      },
      "mode": "DirectQuery"
    }
  ]
}
EOF

echo "$OUT created."
echo ""
echo "Open it on the Windows side (Power BI Desktop is Windows-only) to launch"
echo "pre-configured. When the auth prompt appears:"
echo "  Authentication type: Database"
echo "  Username: the SP display name printed by 02_generate_sp_role_sql.sh"
echo "  Password: contents of pbi_pg_token.txt"
