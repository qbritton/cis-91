
variable "credentials_file" { 
  default = "/home/qui6130/sincere-signal-361922-f506e6f9b1d8.json" 
}

variable "project" {
  default = "sincere-signal-361922"
}

variable "region" {
  default = "us-west1"
}

variable "zone" {
  default = "us-west1-a"
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
  name = "dokuwiki-network-1"
}

resource "google_compute_instance" "vm_instance" {
  name         = "cis-91"
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
    source = google_compute_disk.dokuwiki-data-1.self_link
    device_name = "dokuwiki-data-1"
  }

  service_account {
    email  = google_service_account.dokuwiki-service-account.email
    scopes = ["cloud-platform"]
  }
}

resource "google_service_account" "dokuwiki-service-account" {
  account_id   = "dokuwiki-service-account"
  display_name = "dokuwiki-service-account"
  description = "Service account for dokuwiki"
}

resource "google_project_iam_member" "project_member" {
  role = "roles/owner"
  member = "serviceAccount:${google_service_account.dokuwiki-service-account.email}"
}

resource "google_compute_firewall" "default-firewall" {
  name = "dokuwiki-firewall"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports = ["22", "80"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_disk" "dokuwiki-data-1" {
  name  = "dokuwiki-data-1"
  type  = "pd-ssd"
  zone = "us-west1-a"
  labels = {
    environment = "dev"
  }
  size = "100"
}

resource "google_storage_bucket" "quinns-dokuwiki-bucket" {
  name = "quinns-dokuwiki-bucket"
  location = "US"

   lifecycle_rule {
    condition {
      age = 180
    }
    action {
      type = "Delete"
    }
  }
}


output "external-ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}
