aws_region          = "us-east-1"
cluster_name        = "eks-dev"
kubernetes_version  = "1.35"
allowed_azs         = ["us-east-1a", "us-east-1b"]

# vpc_id     = "vpc-xxxxxxxx"
# subnet_ids = ["subnet-aaaa", "subnet-bbbb"]
# cluster_security_group_ids = ["sg-xxxxxxxx"]

nodegroup_name      = "tools"
node_instance_types = ["t3.medium"]
node_min_size       = 2
node_max_size       = 2
node_desired_size   = 2
node_disk_size      = 20
node_capacity_type  = "ON_DEMAND"
node_labels         = { workload = "tools" }
node_taints         = []

cluster_role_name   = "eks-cluster-role"
node_role_name      = "eks-node-role"

endpoint_public_access  = true
endpoint_private_access = false

public_access_cidrs = ["0.0.0.0/0"]
# cluster_log_types   = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
# enable_encryption   = false
# kms_key_arn         = "arn:aws:kms:us-east-1:123456789012:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
# tags                = { environment = "dev", owner = "platform" }
# update_max_unavailable = 1
# update_max_unavailable_percentage = null
# enable_addons       = true
# addon_versions      = { "vpc-cni" = "v1.x.x-eksbuild.x" }
# enable_cluster_creator_admin = true
# cluster_creator_arn  = "arn:aws:iam::123456789012:role/MyRole"
# access_entries = [
#   {
#     principal_arn = "arn:aws:iam::123456789012:role/PlatformTeam"
#     policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
#     scope_type    = "cluster"
#     namespaces    = []
#   }
# ]
