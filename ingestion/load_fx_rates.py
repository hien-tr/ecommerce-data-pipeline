"""Load daily USD exchange rates from the Frankfurter API into BigQuery raw.fx_rates."""

import requests, os
from google.cloud import bigquery

START_DATE = "2024-01-01"
CURRENCIES = ["EUR", "GBP"]
API_URL = "https://api.frankfurter.dev/v1"
KEY_FILE = os.environ.get("DBT_GOOGLE_KEYFILE", "D:/secrets/dbt-runner.json")
PROJECT = "ecommerce-data-pipeline-511223"
TABLE_ID = f"{PROJECT}.raw.fx_rates"

def extract(start_date, currencies):
    response = requests.get(
        f"{API_URL}/{START_DATE}..",
        params={"base": "USD", "symbols": ",".join(currencies)},
        timeout=30,
    )
    response.raise_for_status()
    return response.json()

def to_rows(data):
    rows = []
    for rate_date, currencies in data["rates"].items():
        for currency, rate in currencies.items():
            rows.append({
                "rate_date": rate_date,
                "base_currency": data["base"],
                "currency": currency,
                "rate": rate,
            })
    return rows

def load(rows):
    client = bigquery.Client.from_service_account_json( KEY_FILE, project = PROJECT)
    job_config = bigquery.LoadJobConfig(
    schema = [
        bigquery.SchemaField("rate_date", "DATE"),
        bigquery.SchemaField("base_currency", "STRING"),
        bigquery.SchemaField("currency", "STRING"),
        bigquery.SchemaField("rate", "FLOAT64"),
    ],
    write_disposition="WRITE_TRUNCATE"
    )
    job = client.load_table_from_json(rows, TABLE_ID,job_config=job_config)
    job.result()
    return job.output_rows

def main():
    data = extract(START_DATE,CURRENCIES)
    rows = to_rows(data)
    loaded = load(rows)
    print(f"Loaded {loaded} rows into, {TABLE_ID}")

if __name__ == "__main__":
    main()
