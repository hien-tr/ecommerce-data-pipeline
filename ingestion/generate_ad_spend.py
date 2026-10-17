"""Generate synthetic daily ad spend by channel and load it into BigQuery raw.ad_spend."""

import os
import random
from datetime import date, datetime, timedelta, timezone

from google.cloud import bigquery

START_DATE = date(2024, 1, 1)
YEARLY_GROWTH = 0.15
SEED = 42
KEY_FILE = os.environ.get("DBT_GOOGLE_KEYFILE", "D:/secrets/dbt-runner.json")
PROJECT = "ecommerce-data-pipeline-511223"
TABLE_ID = f"{PROJECT}.raw.ad_spend"

# Channel names must match TheLook users.traffic_source exactly, so spend joins to revenue.
# Organic has no spend. Each channel bills in its own currency (converted to USD in dbt).
CHANNELS = {
    "Search": "USD",
    "Facebook": "EUR",
    "Display": "GBP",
    "Email": "EUR",
}

# Daily budget in each channel's currency. Derived from TheLook revenue per channel
# divided by a target ROAS (Search 4, Facebook 2.5, Display 2, Email 10), then divided
# by ~1.14 to offset the average weekday (0.93) and growth (1.22) factors.
DAILY_BUDGET = {
    "Search": 900,
    "Facebook": 110,
    "Display": 80,
    "Email": 22,
}

WEEKDAY_FACTOR = {0: 1.0, 1: 1.05, 2: 1.05, 3: 1.0, 4: 0.95, 5: 0.75, 6: 0.7}


def all_dates(start, end):
    """Return every calendar day from start to end, inclusive."""
    days = []
    current = start
    while current <= end:
        days.append(current)
        current += timedelta(days=1)
    return days


def generate_rows(loaded_at):
    """Build one spend row per day and channel."""
    # Fixed seed: the same numbers on every run. Keep dates as the outer loop, so new
    # days only add numbers at the end and past days never change.
    random.seed(SEED)
    rows = []
    end_date = date.today() - timedelta(days=1)
    for spend_date in all_dates(START_DATE, end_date):
        for channel, currency in CHANNELS.items():
            noise = random.uniform(0.8, 1.2)
            weekday = WEEKDAY_FACTOR[spend_date.weekday()]
            years_since_start = (spend_date - START_DATE).days / 365
            growth = (1 + YEARLY_GROWTH) ** years_since_start
            spend = DAILY_BUDGET[channel] * weekday * growth * noise
            rows.append({
                "spend_date": spend_date.isoformat(),
                "channel": channel,
                "currency": currency,
                "spend": round(spend, 2),
                "loaded_at": loaded_at,
            })
    return rows


def load(rows):
    """Replace raw.ad_spend with these rows (full refresh, safe to rerun)."""
    client = bigquery.Client.from_service_account_json(KEY_FILE, project=PROJECT)
    job_config = bigquery.LoadJobConfig(
        schema=[
            bigquery.SchemaField("spend_date", "DATE"),
            bigquery.SchemaField("channel", "STRING"),
            bigquery.SchemaField("currency", "STRING"),
            # NUMERIC, not FLOAT64: exact decimals, so money totals reconcile to the cent.
            bigquery.SchemaField("spend", "NUMERIC"),
            bigquery.SchemaField("loaded_at", "TIMESTAMP"),
        ],
        write_disposition="WRITE_TRUNCATE",
    )
    job = client.load_table_from_json(rows, TABLE_ID, job_config=job_config)
    job.result()
    return job.output_rows


def main():
    loaded_at = datetime.now(timezone.utc).isoformat()
    rows = generate_rows(loaded_at)
    if not rows:
        raise RuntimeError("No rows generated; table left unchanged.")
    loaded = load(rows)
    print(f"Loaded {loaded} rows into {TABLE_ID}")


if __name__ == "__main__":
    main()

