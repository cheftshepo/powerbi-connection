import pandas as pd
from azure.storage.filedatalake import DataLakeServiceClient
from azure.identity import DefaultAzureCredential
import psycopg2
import io

PG_CONN = "host=psql-nsync-aisocial-poc.postgres.database.azure.com dbname=nccip user=nccip_admin password=Nsync2026 sslmode=require"
WORKSPACE_ID  = "0428ea00-031f-47f9-89da-87fc244d134a"
LAKEHOUSE_ID  = "ed4a3465-7255-43ef-b96f-4394f2c4f0e7"
ONELAKE_ACCOUNT = "onelake.dfs.fabric.microsoft.com"

conn = psycopg2.connect(PG_CONN)
credential = DefaultAzureCredential()
datalake = DataLakeServiceClient(
    account_url=f"https://{ONELAKE_ACCOUNT}",
    credential=credential
)
fs_client = datalake.get_file_system_client(WORKSPACE_ID)

queries = {
    # NCA posts with language and confidence — for language breakdown page
    "nca_posts_analytical": """
        SELECT
            id, source, author, published_at, ingested_at,
            nca_passed_at, detected_language, relevance_confidence,
            nca_civic_signals, matched_keywords
        FROM nca_posts
    """,

    # Pipeline funnel + processing speed
    "pipeline_log_analytical": """
        SELECT
            id, raw_post_id, stage, status,
            error_message, duration_ms, created_at
        FROM pipeline_log
    """,

    # Keywords with full context for the hotspot map
    "keywords_analytical": """
        SELECT
            id, keyword, tier, district_code, district_name,
            lm_name, town_name, language, civic_context,
            is_active, created_at
        FROM keywords
    """,

    # Enriched posts with geo unpacked — for point map
    "enriched_posts_geo": """
        SELECT
            id, source, published_at, ingested_at,
            sentiment_label, sentiment_score,
            civic_topics, intent, urgency_score, emotion,
            district_code, district_name, lm_name, town_mentioned,
            geo_tier_resolved, geo_source,
            (geo_coordinates->>'lat')::float AS geo_lat,
            (geo_coordinates->>'lon')::float AS geo_lon,
            escalation_flag, escalation_level,
            relevance_confidence, status
        FROM enriched_posts
        WHERE geo_coordinates IS NOT NULL
          AND geo_coordinates != 'null'::jsonb
    """,

    # Keyword hit counts for hotspot analysis
    "keyword_hits": """
        SELECT
            UNNEST(matched_keywords) AS keyword,
            source,
            published_at::date AS post_date,
            COUNT(*) AS hits
        FROM raw_posts
        WHERE matched_keywords IS NOT NULL
        GROUP BY UNNEST(matched_keywords), source, published_at::date
        ORDER BY hits DESC
    """
}

def upload_df(df, table_name):
    buf = io.BytesIO()
    df.to_parquet(buf, index=False, engine='pyarrow')
    buf.seek(0)
    path = f"{LAKEHOUSE_ID}/Tables/{table_name}/{table_name}.parquet"
    file_client = fs_client.get_file_client(path)
    file_client.upload_data(buf.read(), overwrite=True)
    print(f"  ✓ {table_name} — {len(df)} rows uploaded")

print("Uploading enriched analytical tables to Lakehouse...\n")
for table_name, query in queries.items():
    print(f"  Exporting {table_name}...")
    df = pd.read_sql(query, conn)
    upload_df(df, table_name)

conn.close()
print("\nDone. All analytical tables in Lakehouse.")
