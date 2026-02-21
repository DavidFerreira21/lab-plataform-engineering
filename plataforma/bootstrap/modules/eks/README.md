# Module EKS

Modulo Terraform para provisionar um cluster EKS com:
- IAM base (control plane e node group)
- node group gerenciado
- addons gerenciados (`vpc-cni`, `coredns`, `kube-proxy`)
- controle de acesso via EKS Access API
- criptografia de secrets com KMS (opcional)
- OIDC provider para IRSA (opcional)

## Recursos criados

### IAM
- `aws_iam_role.cluster`
- `aws_iam_role_policy_attachment.cluster_policy`
- `aws_iam_role_policy_attachment.cluster_vpc`
- `aws_iam_role.node`
- `aws_iam_role_policy_attachment.node_worker`
- `aws_iam_role_policy_attachment.node_cni`
- `aws_iam_role_policy_attachment.node_ecr`
- `aws_iam_role_policy_attachment.node_ssm`

### KMS (opcional)
- `aws_kms_key.eks`

### OIDC (opcional)
- `aws_iam_openid_connect_provider.this`

### EKS
- `aws_eks_cluster.this`
- `aws_eks_node_group.this`
- `aws_eks_addon.this`
- `aws_eks_access_entry.this`
- `aws_eks_access_policy_association.this`

## Data sources usados
- `aws_iam_policy_document.cluster_trust`
- `aws_iam_policy_document.node_trust`
- `aws_caller_identity.current`
- `aws_subnet.selected`

## Como este modulo se conecta ao restante do bootstrap
Este modulo entrega os outputs base do cluster (`cluster_name`, `cluster_endpoint`, `cluster_ca`, `cluster_oidc_issuer`, `oidc_provider_arn`) usados pelo modulo `modules/addons`.

Assim, o fluxo completo do bootstrap fica:
1. `module.eks` cria o cluster e OIDC
2. `module.addons` instala Crossplane/External Secrets/Argo/Ingress/Kyverno e configura IRSAs

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
  cluster_security_group_ids = null
  cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  enable_encryption = false

  update_max_unavailable            = 1
  update_max_unavailable_percentage = null

  enable_addons  = true
  addon_versions = {}

  enable_cluster_creator_admin = true
  cluster_creator_arn          = null
  access_entries               = []

  tags = {
    project = "lab-platform-engineering"
    env     = "dev"
  }
}
```

## Variaveis

| Variavel | Tipo | Default | Obrigatoria | Descricao |
|---|---|---|---|---|
| `cluster_name` | `string` | n/a | Sim | Nome do cluster EKS. |
| `kubernetes_version` | `string` | n/a | Sim | Versao do Kubernetes do cluster. |
| `vpc_id` | `string` | n/a | Sim | VPC usada pelo EKS. |
| `subnet_ids` | `list(string)` | n/a | Sim | Subnets usadas pelo cluster e node group. |
| `cluster_security_group_ids` | `list(string)` | `null` | Nao | Security groups adicionais do control plane. |
| `nodegroup_name` | `string` | n/a | Sim | Nome do managed node group. |
| `node_instance_types` | `list(string)` | n/a | Sim | Tipos de instancia do node group. |
| `node_min_size` | `number` | n/a | Sim | Tamanho minimo do node group. |
| `node_max_size` | `number` | n/a | Sim | Tamanho maximo do node group. |
| `node_desired_size` | `number` | n/a | Sim | Tamanho desejado do node group. |
| `node_disk_size` | `number` | n/a | Sim | Tamanho do disco dos nodes (GiB). |
| `node_capacity_type` | `string` | n/a | Sim | Tipo de capacidade (`ON_DEMAND`/`SPOT`). |
| `node_labels` | `map(string)` | n/a | Sim | Labels aplicados aos nodes. |
| `node_taints` | `list(object({ key = string, value = string, effect = string }))` | n/a | Sim | Taints aplicados aos nodes. |
| `cluster_role_name` | `string` | n/a | Sim | Nome da IAM role do control plane. |
| `node_role_name` | `string` | n/a | Sim | Nome da IAM role dos nodes. |
| `endpoint_public_access` | `bool` | n/a | Sim | Habilita endpoint publico do EKS. |
| `endpoint_private_access` | `bool` | n/a | Sim | Habilita endpoint privado do EKS. |
| `public_access_cidrs` | `list(string)` | `[]` | Nao | CIDRs permitidos no endpoint publico. |
| `cluster_log_types` | `list(string)` | `[`api`,`audit`,`authenticator`,`controllerManager`,`scheduler`]` | Nao | Tipos de logs do control plane. |
| `enable_encryption` | `bool` | `false` | Nao | Habilita criptografia de secrets com KMS. |
| `tags` | `map(string)` | `{}` | Nao | Tags aplicadas aos recursos. |
| `update_max_unavailable` | `number` | `1` | Nao | Maximo de nodes indisponiveis no update. |
| `update_max_unavailable_percentage` | `number` | `null` | Nao | Percentual maximo indisponivel no update. |
| `enable_addons` | `bool` | `true` | Nao | Habilita addons gerenciados do EKS. |
| `addon_versions` | `map(string)` | `{}` | Nao | Versoes dos addons (`vpc-cni`, `coredns`, `kube-proxy`). |
| `enable_cluster_creator_admin` | `bool` | `true` | Nao | Concede admin do cluster ao criador. |
| `cluster_creator_arn` | `string` | `null` | Nao | ARN explicito para admin. |
| `access_entries` | `list(object({ principal_arn = string, policy_arn = string, scope_type = optional(string, "cluster"), namespaces = optional(list(string), []) }))` | `[]` | Nao | Entradas adicionais via EKS Access API. |
| `enable_oidc_provider` | `bool` | `true` | Nao | Cria IAM OIDC provider para IRSA. |

## Outputs

| Output | Descricao |
|---|---|
| `cluster_name` | Nome do cluster EKS. |
| `cluster_endpoint` | Endpoint da API do cluster. |
| `cluster_ca` | CA do cluster em base64. |
| `cluster_oidc_issuer` | URL do OIDC issuer do cluster. |
| `oidc_provider_arn` | ARN do IAM OIDC provider para IRSA. |
| `nodegroup_name` | Nome do managed node group. |
| `vpc_id` | VPC usada pelo cluster. |
| `subnet_ids` | Subnets usadas pelo cluster. |
| `kms_key_arn` | ARN da KMS key usada na criptografia de secrets. |

## Regras importantes
- `subnet_ids` deve conter pelo menos 2 subnets.
- Todas as `subnet_ids` devem pertencer ao `vpc_id`.
- Se `endpoint_public_access = true`, `public_access_cidrs` deve estar preenchido.
- `update_max_unavailable` e `update_max_unavailable_percentage` sao mutuamente exclusivos.
