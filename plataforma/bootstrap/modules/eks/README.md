# Module EKS

Este modulo provisiona um cluster EKS com Node Group, roles IAM, acesso via EKS Access e addons gerenciados.

## Entradas
- `vpc_id` / `subnet_ids`: VPC e subnets onde o cluster sera criado.
- `cluster_name`, `kubernetes_version`.
- `nodegroup_name`, `node_instance_types`, `node_min_size`, `node_max_size`, `node_desired_size`, `node_disk_size`, `node_capacity_type`.
- `endpoint_public_access`, `endpoint_private_access`, `public_access_cidrs`.
- `cluster_security_group_ids` (opcional).
- `cluster_log_types`.
- `enable_encryption` + `kms_key_arn` (se vazio, cria KMS automaticamente).
- `enable_addons` + `addon_versions` (padroes da console: vpc-cni, coredns, kube-proxy).
- `enable_cluster_creator_admin` / `cluster_creator_arn` / `access_entries`.
- `tags`.

## Saidas
- `cluster_name`, `cluster_endpoint`, `cluster_ca`.
- `nodegroup_name`.
- `vpc_id`, `subnet_ids`.
- `kms_key_arn`.

## Observacoes
- `subnet_ids` deve conter pelo menos 2 subnets e todas devem pertencer ao `vpc_id`.
- Se `endpoint_public_access = true`, `public_access_cidrs` e obrigatorio.
