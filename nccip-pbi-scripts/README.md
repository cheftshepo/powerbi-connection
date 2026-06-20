# NCCIP → Power BI (service principal auth) — tonight's run order

Run these **in your own terminal**, on the machine where `az` is logged in
as *you* (with Key Vault + Postgres admin rights), and where you can
eventually open Power BI Desktop (Windows — open the .pbids from the
Windows side if you're on WSL).

These scripts can't run from a Claude.ai sandbox — no network path to your
Azure tenant from there. That's why they're handed to you as files instead.

## One-time setup

```bash
chmod +x *.sh
az login   # as YOURSELF — needed for steps 00-02
```

`config.env` is pre-filled with your known resource names (vault, server,
resource group, db). Leave those unless they've changed.

## Run order

| # | Script | What it does |
|---|---|---|
| 0 | `./00_list_keyvault_secrets.sh` | Lists vault secrets so you can identify the SP's client-id/secret/tenant-id names |
| — | edit `config.env` | Paste the matching names into `KV_SECRET_NAME_*` |
| 1 | `./01_check_postgres_aad.sh` | Confirms AAD auth is enabled + lists current AAD admins |
| 2 | `./02_generate_sp_role_sql.sh` | Writes `sp_postgres_role.generated.sql` with the SP's display name filled in (doesn't run it) |
| — | run the SQL | `psql -h $PG_HOST -U ncadmin -d nccip_db --set=sslmode=require -f sp_postgres_role.generated.sql` — connect as an existing admin, not the SP |
| 3 | `./03_get_pbi_token.sh` | Gets a fresh AAD token for Postgres, scoped to the SP. **Expires ~1hr** — rerun whenever it lapses during demo prep |
| 4 | `./04_make_pbids.sh` | Generates `nccip_dashboard.pbids` — open it to launch Power BI Desktop pre-configured |
| 5 | `./05_verify_data_flowing.sh` | Confirms the SP can actually SELECT data + runs the `geo_source = 'unresolved'` gap check |
| 6 | `./06_check_views_exist.sh` | ⚠️ Checks whether `v_posts_with_geo` / `v_sentiment_trend` / `v_escalations` / `v_pending_responses` exist. I don't have these views in what I know of your schema (only `raw_posts`, `nca_posts`, `enriched_posts`, `embeddings_v2`, `trends_cache`, `pipeline_log` are confirmed built) — run this early so you're not discovering a missing view live in Power BI |

## In Power BI Desktop (manual — it's a GUI, no script for this part)

When prompted on the .pbids connection:
- **Authentication type:** Database
- **Username:** SP display name (exact, case-sensitive — printed by step 2)
- **Password:** contents of `pbi_pg_token.txt`

**Page 1 — Executive Overview:**
- Card: `COUNT(v_posts_with_geo[id])`
- Filled map: location = `district_name`, color = `AVERAGE(sentiment_score)`
- Line chart: `v_sentiment_trend[week_label]` (axis) vs `avg_sentiment` (value)
- Model relationship: `v_posts_with_geo[district_code]` ↔ `v_sentiment_trend[district_code]`, many-to-many

If step 6 shows those views don't exist, swap the visuals to query
`enriched_posts` directly (or build the views first — your call given time
left before tomorrow).

## What's different from the original runbook

- `03_get_pbi_token.sh` logs in as the SP inside an isolated `AZURE_CONFIG_DIR`,
  so it doesn't clobber your normal `az` session — you can re-run steps 00-02
  afterward without logging back in as yourself.
- Added `06_check_views_exist.sh` since the four views the dashboard plan
  depends on aren't in anything I know was built yet.
- `.gitignore` included so the token / generated SQL / pbids never land in
  a commit by accident.

## Reminders carried over from your notes

- Token-as-password is a **demo-day workaround**, not a permanent fix.
  Unattended Power BI Service refresh needs a gateway — separate task, not tonight.
- Marketplace listing is **not** tonight's job. Tomorrow's presentation can show
  the architecture as "Marketplace-shaped" without claiming it's listed.
- Don't paste `config.env` contents, the generated SQL, or `pbi_pg_token.txt`
  into chat — keep secrets local. If a step fails, paste the exact command +
  raw error and I can debug from that alone.
