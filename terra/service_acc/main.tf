resource "google_service_account" "service_account" {
  account_id = "apig-service-account"
  display_name = "API G Service Account"
  project = "lb-apig-cr-test"
}
