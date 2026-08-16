resource "google_bigquery_dataset" "analytics" {
  dataset_id                  = "hadp_analytics_${var.environment}"
  location                    = var.region
  description                 = "Serving layer for analytics on ingested events"
  default_table_expiration_ms = null
}

resource "google_bigquery_table" "events" {
  dataset_id          = google_bigquery_dataset.analytics.dataset_id
  table_id            = "events"
  deletion_protection = true

  time_partitioning {
    type  = "DAY"
    field = "event_time"
  }

  clustering = ["event_type"]

  schema = <<EOF
[
  {"name": "event_id",   "type": "STRING",    "mode": "REQUIRED"},
  {"name": "event_type", "type": "STRING",    "mode": "REQUIRED"},
  {"name": "payload",    "type": "JSON",      "mode": "NULLABLE"},
  {"name": "event_time", "type": "TIMESTAMP", "mode": "REQUIRED"},
  {"name": "ingested_at","type": "TIMESTAMP", "mode": "REQUIRED"}
]
EOF
}