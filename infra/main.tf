terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      
    }
    google-beta = {
      source = "hashicorp/google-beta"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_service_account" "sa" {
  account_id   = "cloud-run-invoker"
  display_name = "Cloud Run Invoker"
}

resource "google_project_service" "cloud_run_api" {
  service = "run.googleapis.com"
}

resource "google_cloud_run_service" "default" {
  name     = "cloud-run-service"
  location = var.region

  template {
    spec {
      containers {
        image = var.hello_app_image_url
      }
    }
  }

  depends_on = [
    google_project_service.cloud_run_api
  ]
}

data "google_iam_policy" "cr_invoker" {
  binding {
    role    = "roles/run.invoker"
    members = ["serviceAccount:${google_service_account.sa.email}"]
  }
}

resource "google_cloud_run_service_iam_policy" "policy" {
  location    = var.region
  service     = google_cloud_run_service.default.name
  policy_data = data.google_iam_policy.cr_invoker.policy_data
}

locals {
  gateway_id = "api-gw"
}

resource "google_api_gateway_api" "api_gw" {
  provider     = google-beta
  api_id       = local.gateway_id
  display_name = "The API Gateway"
}

resource "google_api_gateway_api_config" "api_gw" {
  provider      = google-beta
  api           = google_api_gateway_api.api_gw.api_id
  api_config_id = "config"

  openapi_documents {
    document {
      path     = "spec.yaml"
      contents = filebase64("spec.yaml")
    }
  }

  gateway_config {
    backend_config {
      google_service_account = google_service_account.sa.email
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_api_gateway_gateway" "api_gw" {
  provider   = google-beta
  api_config = google_api_gateway_api_config.api_gw.id
  gateway_id = local.gateway_id
}

resource "google_compute_region_network_endpoint_group" "neg" {
  provider              = google-beta
  region                = var.region
  name                  = "apig-neg"
  network_endpoint_type = "SERVERLESS"

  serverless_deployment {
    platform = "apigateway.googleapis.com"
    resource = local.gateway_id
  }

  lifecycle {
    create_before_destroy = true
  }
}


module "lb-http" {
  source            = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version           = "~> 6.3"

  project           = var.project
  name              = "my-lb"

  ssl                             = true
  managed_ssl_certificate_domains = ["denis-birthday.nl"]
  https_redirect                  = true

  cdn = false
  create_address = true

  backends = {
    default = {
      description                     = null
      enable_cdn                      = false
      custom_request_headers          = null
      custom_response_headers         = null
      security_policy                 = null

      log_config = {
        enable = false
        sample_rate = 1.0
      }

      groups = [
        {
          # Your serverless service should have a NEG created that's referenced here.
          group = google_compute_region_network_endpoint_group.neg.id
        }
      ]

      iap_config = {
        enable               = false
        oauth2_client_id     = null
        oauth2_client_secret = null
      }
    }
  }
}
