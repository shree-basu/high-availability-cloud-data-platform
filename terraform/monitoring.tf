resource "google_monitoring_notification_channel" "email" {
  display_name = "HADP On-Call Email"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
}

# ALERT 1: anything in the dead-letter topic.
resource "google_monitoring_alert_policy" "dlq_messages" {
  display_name = "DLQ has messages (${var.environment})"
  combiner     = "OR"

  conditions {
    display_name = "Dead-letter backlog > 0"
    condition_threshold {
      filter = join(" AND ", [
        "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\"",
        "resource.label.subscription_id=\"${google_pubsub_subscription.dead_letter_sub.name}\"",
      ])
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "60s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}

# ALERT 2: ingestion backlog growing.
resource "google_monitoring_alert_policy" "ingestion_backlog" {
  display_name = "Ingestion backlog high (${var.environment})"
  combiner     = "OR"

  conditions {
    display_name = "Undelivered messages > 1000"
    condition_threshold {
      filter = join(" AND ", [
        "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\"",
        "resource.label.subscription_id=\"${google_pubsub_subscription.ingestion_sub.name}\"",
      ])
      comparison      = "COMPARISON_GT"
      threshold_value = 1000
      duration        = "300s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}