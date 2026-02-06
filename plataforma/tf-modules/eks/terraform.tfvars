cluster_name = "eks-dev"
aws_region   = "us-east-1"
allowed_azs  = ["us-east-1a", "us-east-1b"]

# Preencha com o ID da VPC
vpc_id = ""

# Preencha com os IDs das subnets
subnet_ids = []

tags = {
  Environment = "dev"
  Lab         = "plataform Engineering"
}
