terraform {
  backend "s3" {
    bucket = "terra-vprofile-state33"
    key    = "terraform/backend"
    region = "us-east-1"
  }
}