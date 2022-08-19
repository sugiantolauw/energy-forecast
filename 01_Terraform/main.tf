terraform {
    required_version = ">= 1.0"
    backend "local" {} # Can change from "local" to "gcs" or "s3" to preserve tf-state online
    required_providers {
        google = {
            source = "hashicorp/google"
        }
    }
}

provider "google" {
    project = var.project
    region = var.region
    # credentials = # use this if we dont want to set env-var  GOOGLE_APPLICATION_CREDENTIALS
}

# Data Lake Bucket
# Ref: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
resource "google_storage_bucket" "data-lake-bucket" {
    name = "${local.data_lake_bucket}_${var.project}" # Concat DL bucket & project name for unique name
    location = var.region

    # Optional but recommended
    storage_class = var.storage_class
    uniform_bucket_level_access = true

    versioning {
      enabled = true
    }

    lifecycle_rule {
      action {
        type = "Delete"
      }
      condition {
        age = 30 // days
      }
    }
  
  force_destroy = true
}

# DWH
# Ref: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset
resource "google_bigquery_dataset" "dataset" {
    dataset_id = var.BQ_DATASET 
    project = var.project
    location = var.region
}

# A Single compute instance
resource "google_compute_instance" "default"{
    name = "energy-data-proj.vm"
    machine_type = "e2-standard-4"
    zone = var.zone

    boot_disk {
      initialize_params{
        image = "ubuntu-1804-lts"
        size = "30"
      }
    }

    network_interface {
      network = "default"
        access_config {
        # include this section to give VM an external IP Address  
        } 
    }

    metadata = {
        ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_file)}"
    }
}

resource "google_storage_bucket" "mlflow-runs" {

    name = "mlflow-runs-${var.project}" # Concat DL bucket and project name for unique naming
    location = var.region

    # Optional but recommended
    storage_class = var.storage_class
    uniform_bucket_level_access = true

    versioning {
      enabled = true
    }

    lifecycle_rule {
      action {
        type = "Delete"
      }
      condition {
        age = 30 // days
      }
    }

    force_destroy = true
}