import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
from azure.storage.filedatalake import DataLakeServiceClient
from azure.identity import DefaultAzureCredential
import psycopg2
import io

# --- Config ---
PG_CONN = "host=psql-nsync-aisocial-poc.postgres.database.azure.com dbname=nccip user=nccip_admin password=Nsync2026 sslmode=require"
WORKSPACE_ID  = "0428ea00-031f-47f9-89da-87fc244d134a"
LAKEHOUSE_ID  = "ed4a3465-7255-43ef-b96f-4394f2c4f0e7"
ONELAKE_ACCOUNT = "onelake.dfs.fabric.microsoft.com"

# Tables/views to export
TABLES = [
    "enriched_posts",
    "v_posts_with_geo",
    "v_sentiment_trend",
    "v_escalations",
    "v_pending_responses",
]

# --- Connect ---
print("Connecting to Postgres...")
conn = psycopg2.connect(PG_CONN)

# --- OneLake client ---
print("Authenticating to OneLake...")
credential = DefaultAzureCredential()
datalake = DataLakeServiceClient(
    account_url=f"https://{ONELAKE_ACCOUNT}",
    credential=credential
)

fs_client = datalake.get_file_system_client(WORKSPACE_ID)

for table in TABLES:
    print(f"  Exporting {table}...")
    df = pd.read_sql(f"SELECT * FROM {table}", conn)

    # Drop vector columns — pyarrow can't serialize pgvector
    drop_cols = [c for c in df.columns if df[c].dtype == object and 'embedding' in c.lower()]
    df = df.drop(columns=drop_cols, errors='ignore')

    # Serialize to parquet in memory
    buf = io.BytesIO()
    df.to_parquet(buf, index=False, engine='pyarrow')
    buf.seek(0)

    # Upload path: Tables/<table_name>/<table_name>.parquet
    path = f"{LAKEHOUSE_ID}/Tables/{table}/{table}.parquet"
    print(f"    Uploading to {path} ({len(df)} rows)...")

    file_client = fs_client.get_file_client(path)
    file_client.upload_data(buf.read(), overwrite=True)
    print(f"    Done.")

conn.close()
print("\nAll tables uploaded. Lakehouse tables will appear in Fabric within ~1 min.")
