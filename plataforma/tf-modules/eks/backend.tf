terraform {
  backend "s3" {
    bucket       = "tfstate-terraform-lab-plataform-engineering"
    key          = "eks/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}
