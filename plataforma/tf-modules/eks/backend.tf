terraform {
  backend "s3" {
    bucket       = "tfstate-814436217857-us-east-1"
    key          = "eks/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}
