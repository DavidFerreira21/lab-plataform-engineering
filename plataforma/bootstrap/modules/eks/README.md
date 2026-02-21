# Module EKS

Modulo Terraform responsavel por provisionar o cluster EKS e sua base operacional.

## O que este modulo cria
- IAM roles do control plane e node group.
- Cluster EKS.
- Managed node group.
- Add-ons gerenciados AWS (`vpc-cni`, `coredns`, `kube-proxy`).
- Entradas de acesso via EKS Access API.
- KMS para secrets (opcional).
- OIDC provider para IRSA (opcional).

## Como conecta com o restante do bootstrap
Outputs deste modulo alimentam `modules/addons`:
- `cluster_name`
- `cluster_endpoint`
- `cluster_ca`
- `cluster_oidc_issuer`
- `oidc_provider_arn`
- `vpc_id`

Com isso, o modulo de add-ons consegue configurar IRSA e publicar metadados de ambiente para o Crossplane.

## Exemplo de uso
```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name       = "eks-dev"
  kubernetes_version = "1.35"

  vpc_id     = "vpc-xxxxxxxx"
  subnet_ids = ["subnet-aaaa", "subnet-bbbb"]

  cluster_role_name = "eks-cluster-role"
  node_role_name    = "eks-node-role"

  nodegroup_name      = "tools"
  node_instance_types = ["t3.medium"]
  node_min_size       = 2
  node_max_size       = 3
  node_desired_size   = 2
  node_disk_size      = 20
  node_capacity_type  = "ON_DEMAND"
  node_labels         = { workload = "tools" }
  node_taints         = []

  endpoint_public_access  = true
  endpoint_private_access = false
  public_access_cidrs     = ["0.0.0.0/0"]

  enable_addons = true

  enable_oidc_provider = true
}
```

## Inputs mais relevantes
- Rede: `vpc_id`, `subnet_ids`, `cluster_security_group_ids`.
- Node group: `node_*`.
- API endpoint: `endpoint_public_access`, `endpoint_private_access`, `public_access_cidrs`.
- Acesso: `enable_cluster_creator_admin`, `cluster_creator_arn`, `access_entries`.
- IRSA base: `enable_oidc_provider`.

## Outputs principais
- `cluster_name`
- `cluster_endpoint`
- `cluster_ca`
- `cluster_oidc_issuer`
- `oidc_provider_arn`
- `vpc_id`
- `subnet_ids`

## Regras importantes
- `subnet_ids` deve conter pelo menos 2 subnets.
- Todas as `subnet_ids` devem pertencer a `vpc_id`.
- `update_max_unavailable` e `update_max_unavailable_percentage` sao mutuamente exclusivos.
- Se `endpoint_public_access=true`, configure `public_access_cidrs` explicitamente em ambientes reais.

## Troubleshooting
- Falha de auth no Kubernetes provider apos apply: rode `aws eks update-kubeconfig` para o cluster correto.
- IRSA quebrando em workloads: valide se `enable_oidc_provider=true` e se `oidc_provider_arn` foi exportado no output.
