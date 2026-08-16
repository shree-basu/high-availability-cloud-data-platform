resource "google_storage_bucket" "dataflow" {
  name                        = "${var.project_id}-hadp-dataflow-${var.environment}"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition { age = 7 }
    action { type = "Delete" }
  }
}