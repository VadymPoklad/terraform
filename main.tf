module "vpc" {
  source = "./modules/vpc"

  environment           = "jira-clone"
  vpc_cidr              = "10.0.0.0/16"
  azs                   = ["us-east-1a", "us-east-1b"]
  public_subnets_cidr   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets_cidr  = ["10.0.10.0/24", "10.0.11.0/24"]
  database_subnets_cidr = ["10.0.20.0/24", "10.0.21.0/24"]
}