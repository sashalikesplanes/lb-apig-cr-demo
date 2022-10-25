output "cloudrun_url" {
  value = google_cloud_run_service.default.status[0].url
}

output "gateway_url" {
  value = google_api_gateway_gateway.api_gw.default_hostname
}

output "service_account_email" {
  value = google_service_account.sa.email
}

output "lb-url" {
  value = module.lb-http.external_ip
}
