# ---------- MAIN INGESTION TOPIC ----------
resource "google_pubsub_topic" "ingestion" {
  name                       = "hadp-ingestion-${var.environment}"
  message_retention_duration = "86400s" # 24h retention for replay
}

# ---------- DEAD-LETTER TOPIC ----------
resource "google_pubsub_topic" "dead_letter" {
  name                       = "hadp-ingestion-dlq-${var.environment}"
  message_retention_duration = "604800s" # 7 days
}

# ---------- MAIN SUBSCRIPTION ----------
resource "google_pubsub_subscription" "ingestion_sub" {
  name  = "hadp-ingestion-sub-${var.environment}"
  topic = google_pubsub_topic.ingestion.id

  ack_deadline_seconds = 60

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  # After 5 failed attempts, route to the dead-letter topic.
  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 5
  }

  expiration_policy {
    ttl = "" # never expire the subscription
  }
}

# ---------- DEAD-LETTER SUBSCRIPTION ----------
resource "google_pubsub_subscription" "dead_letter_sub" {
  name                 = "hadp-ingestion-dlq-sub-${var.environment}"
  topic                = google_pubsub_topic.dead_letter.id
  ack_deadline_seconds = 60
}

# ---------- IAM wiring for dead-lettering ----------
data "google_project" "current" {}

locals {
  pubsub_sa = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_topic_iam_member" "dlq_publisher" {
  topic  = google_pubsub_topic.dead_letter.id
  role   = "roles/pubsub.publisher"
  member = local.pubsub_sa
}

resource "google_pubsub_subscription_iam_member" "dlq_subscriber" {
  subscription = google_pubsub_subscription.ingestion_sub.id
  role         = "roles/pubsub.subscriber"
  member       = local.pubsub_sa
}