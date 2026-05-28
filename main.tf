module "vpc" {
  source = "./modules/vpc"

  environment           = "jira-clone"
  vpc_cidr              = "10.0.0.0/16"
  azs                   = ["us-east-1a", "us-east-1b"]
  public_subnets_cidr   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets_cidr  = ["10.0.10.0/24", "10.0.11.0/24"]
  database_subnets_cidr = ["10.0.20.0/24", "10.0.21.0/24"]
}

module "db" {
  source = "./modules/db"

  environment          = "jira-clone"
  vpc_id               = module.vpc.vpc_id
  vpc_cidr             = "10.0.0.0/16"
  db_subnet_group_name = module.vpc.db_subnet_group_name

  depends_on = [module.vpc]
}

module "ec2" {
  source = "./modules/ec2"

  environment        = "jira-clone"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  ami_id             = "ami-08ea0e1104fdbba72"
}