
variable "credentials_file" { 
  default = "/home/qui6130/sincere-signal-361922-f506e6f9b1d8.json" 
}

variable "project" {
  default = "sincere-signal-361922"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  region  = var.region
  zone    = var.zone 
  project = var.project
}

resource "google_compute_network" "vpc_network" {
  name = "cis91-network"
}

resource "google_compute_instance" "vm_instance" {
  name         = "cis91"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }

  attached_disk {
    source = google_compute_disk.lab09.self_link
    device_name = "lab09"
  }

  attached_disk {
    source = google_compute_disk.blockstorage.self_link
    device_name = "blockstorage"
  }

service_account {
    email  = google_service_account.lab08-service-account.email
    scopes = ["cloud-platform"]
  }
}

resource "google_service_account" "lab08-service-account" {
  account_id   = "lab08-service-account"
  display_name = "lab08-service-account"
  description = "Service account for lab 08"
}

resource "google_project_iam_member" "project_member" {
  role = "roles/owner"
  member = "serviceAccount:${google_service_account.lab08-service-account.email}"
}

resource "google_compute_firewall" "default-firewall" {
  name = "default-firewall"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports = ["22", "80", "3000", "5000"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_disk" "lab09" {
  name  = "lab09"
  type  = "pd-ssd"
  labels = {
    environment = "dev"
  }
  size = "16"
}

resource "google_compute_disk" "blockstorage" {
  name  = "blockstorage"
  type  = "pd-ssd"
  labels = {
    environment = "dev"
  }
  size = "100"
}

resource "google_storage_bucket" "quinns-cloud-bucket" {
  name = "quinns-cloud-bucket"
  location = "US"
}

output "external-ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}
