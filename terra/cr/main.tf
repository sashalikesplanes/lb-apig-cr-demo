provider "google" {
  project = "lb-apig-cr-test"
}

variable "region" {
  type = string
  default = "europe-west1"
}

resource "google_project_service" "cloud_run_api" {
  service = "run.googleapis.com"
}

resource "google_cloud_run_service" "cloud_run" {
  name = "hello"
  location = var.region

  template {
    spec {
      containers {
        image = "europe-west4-docker.pkg.dev/lb-apig-cr-test/image/hello-app"

      }
    }
  }
  depends_on = [
    google_project_service.cloud_run_api
  ]
}

data "google_iam_policy" "all_users_policy" {
  binding {
    role = "roles/run.invoker"
    members = ["serviceAccount:apig-service-account@lb-apig-cr-test.iam.gserviceaccount.com"]
  }
}

resource "google_cloud_run_service_iam_policy" "all_users_iam_policy" {
  location = google_cloud_run_service.cloud_run.location
  service = google_cloud_run_service.cloud_run.name

  policy_data = data.google_iam_policy.all_users_policy.policy_data
}

output "service_url" {
  value = google_cloud_run_service.cloud_run.status[0].url
}
