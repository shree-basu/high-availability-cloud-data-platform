output "ingestion_topic" {
  value = google_pubsub_topic.ingestion.id
}

output "dead_letter_topic" {
  value = google_pubsub_topic.dead_letter.id
}

output "vpc_network" {
  value = google_compute_network.vpc.id
}

output "bigquery_dataset" {
  value = google_bigquery_dataset.analytics.dataset_id
}

output "cloudsql_primary_connection" {
  value = google_sql_database_instance.primary.connection_name
}