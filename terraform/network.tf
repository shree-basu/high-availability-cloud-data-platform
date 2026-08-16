# Dedicated VPC — isolates our platform from the default network.
resource "google_compute_network" "vpc" {
  name                    = "hadp-vpc-${var.environment}"
  auto_create_subnetworks = false
}

# Subnet where our compute/processing lives.
resource "google_compute_subnetwork" "subnet" {
  name          = "hadp-subnet-${var.environment}"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# --- Private Service Access: gives Cloud SQL a PRIVATE IP in our VPC ---
resource "google_compute_global_address" "private_ip_range" {
  name          = "hadp-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}