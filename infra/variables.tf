variable "project" {
  default = "lb-apig-cr-test"
}

variable "region" {
  default = "europe-west1"
}

variable "zone" {
  default = "europe-west1-b"
}

variable "hello_app_image_url" {
  default = "europe-west4-docker.pkg.dev/lb-apig-cr-test/image/hello-app"
}
