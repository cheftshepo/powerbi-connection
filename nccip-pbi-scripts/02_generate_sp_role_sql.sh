#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.env"
source "$(dirname "$0")/lib_sp.sh"
load_sp_creds

SP_DISPLAY_NAME=$(az ad sp show --id "$SP_CLIENT_ID" --query displayName -o tsv)
echo "SP display name: $SP_DISPLAY_NAME"

PRINCIPAL_SQL="$(dirname "$0")/sp_postgres_principal.generated.sql"
GRANTS_SQL="$(dirname "$0")/sp_postgres_grants.generated.sql"

cat > "$PRINCIPAL_SQL" <<SQL
-- pgaadauth_create_principal only exists in the special 'postgres' maintenance
-- database on Flexible Server. Run THIS file connected to -d postgres.
SELECT * FROM pgaadauth_create_principal('${SP_DISPLAY_NAME}', false, false);
SQL

cat > "$GRANTS_SQL" <<SQL
-- Run THIS file connected to -d ${PG_DB_NAME} (after the principal file above)
GRANT CONNECT ON DATABASE ${PG_DB_NAME} TO "${SP_DISPLAY_NAME}";
GRANT USAGE ON SCHEMA public TO "${SP_DISPLAY_NAME}";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "${SP_DISPLAY_NAME}";
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO "${SP_DISPLAY_NAME}";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "${SP_DISPLAY_NAME}";
SQL

echo "Wrote $PRINCIPAL_SQL (run against -d postgres)"
echo "Wrote $GRANTS_SQL (run against -d ${PG_DB_NAME})"
