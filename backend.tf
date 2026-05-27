terraform {
  backend "s3" {
    bucket = "jira-clone-terraform-state"
    key    = "infrastructure/terraform.tfstate"
    region = "us-east-1"
  }
}