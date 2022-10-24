variable "region" {
  type = string
  default = "europe-west1"
}

locals {
  api_config_id_prefix = "api"
  api_gateway_container_id = "api-gw"
  gateway_id = "gw"
}

resource "google_api_gateway_api" "api_gw" {
  provider = google-beta
  project = "lb-apig-cr-test"
  api_id = local.api_gateway_container_id
  display_name = "The API Gateway"
}

resource "google_api_gateway_api_config" "api_cfg" {
  provider = google-beta
  project = "lb-apig-cr-test"
  api = google_api_gateway_api.api_gw.api_id
  api_config_id_prefix = local.api_config_id_prefix
  display_name = "The Config"

  openapi_documents {
    document {
      path = "spec.yaml"
      contents = filebase64("spec.yaml")
    }
  }

  gateway_config {
    backend_config {
      google_service_account = "apig-service-account@lb-apig-cr-test.iam.gserviceaccount.com"
    }
  }
}

resource "google_api_gateway_gateway" "gw" {
  provider = google-beta
  project = "lb-apig-cr-test"
  region = var.region
  
  api_config = google_api_gateway_api_config.api_cfg.id

  gateway_id = local.gateway_id
  display_name = "The Gateway"

  depends_on = [google_api_gateway_api_config.api_cfg]
}
