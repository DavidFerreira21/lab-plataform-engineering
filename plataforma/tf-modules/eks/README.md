# Modulo EKS

Wrapper simples do `terraform-aws-modules/eks/aws` com opcional de IAM/SQS para Karpenter.

**O que este modulo faz**
- Cria o cluster EKS usando o modulo upstream.
- Se `enable_karpenter = true`, cria roles, policies e instance profile do IAM, alem de uma fila SQS para interrupcoes.
- Suporta IRSA e perfil Fargate do Karpenter quando habilitado.

**Defaults de rede**
Se `vpc_id` estiver vazio ou `subnet_ids` estiver vazio, o modulo usa a VPC default da AWS e suas subnets via data sources.

## Recursos criados

**Data sources**
- `data.aws_vpc.default`
- `data.aws_subnets.default`

**Recursos (quando `enable_karpenter = true`)**
- `aws_sqs_queue.karpenter_interruptions`
- `aws_iam_role.karpenter_controller`
- `aws_iam_policy.karpenter_controller`
- `aws_iam_role_policy_attachment.karpenter_controller`
- `aws_iam_role.karpenter_node`
- `aws_iam_role_policy_attachment.karpenter_node_worker`
- `aws_iam_role_policy_attachment.karpenter_node_cni`
- `aws_iam_role_policy_attachment.karpenter_node_ecr`
- `aws_iam_role_policy_attachment.karpenter_node_ssm`
- `aws_iam_instance_profile.karpenter`

**Recursos adicionais**
- `kubernetes_config_map_v1.aws_auth`
- `module.eks`

## Inputs

| Nome | Tipo | Default | Descricao |
| --- | --- | --- | --- |
| `cluster_name` | `string` | n/a | Nome do cluster EKS. |
| `aws_region` | `string` | `"us-east-1"` | Regiao AWS para os providers. |
| `cluster_version` | `string` | `"1.35"` | Versao do Kubernetes. |
| `allowed_azs` | `list(string)` | `["us-east-1a", "us-east-1b"]` | AZs permitidas para as subnets do control plane. |
| `vpc_id` | `string` | `""` | ID da VPC do cluster. Se vazio, usa a VPC default. |
| `subnet_ids` | `list(string)` | `[]` | Subnets do cluster e node groups. Se vazio, usa subnets da VPC default. |
| `fargate_subnet_ids` | `list(string)` | `[]` | Subnets privadas para Fargate. Se vazio, usa as privadas de `subnet_ids`/default. |
| `enable_karpenter` | `bool` | `true` | Habilita dependencias IAM e SQS do Karpenter. |
| `enable_fargate_karpenter` | `bool` | `true` | Cria profile Fargate para o namespace do Karpenter. |
| `karpenter_namespace` | `string` | `"karpenter"` | Namespace usado pelo controller do Karpenter no Fargate. |
| `karpenter_service_account` | `string` | `"karpenter"` | Service account do controller do Karpenter. |
| `karpenter_controller_role_name` | `string` | `"karpenter-controller"` | Nome da role IAM do controller do Karpenter. |
| `karpenter_node_role_name` | `string` | `"karpenter-node"` | Nome da role IAM dos nodes criados pelo Karpenter. |
| `aws_auth_roles` | `list(object)` | `[]` | Entradas adicionais do `aws-auth` mapRoles. |
| `tags` | `map(string)` | `{}` | Tags aplicadas aos recursos. |

## Outputs

| Nome | Descricao |
| --- | --- |
| `cluster_name` | Nome do cluster EKS. |
| `cluster_endpoint` | Endpoint do API server do EKS. |
| `cluster_ca_certificate` | CA em Base64. |
| `cluster_security_group_id` | Security group do control plane. |
| `node_security_group_id` | Security group do node group gerenciado. |
| `oidc_provider_arn` | ARN do provider OIDC para IRSA. |
| `karpenter_controller_role_arn` | ARN da role do controller do Karpenter (ou `null`). |
| `karpenter_node_role_arn` | ARN da role dos nodes do Karpenter (ou `null`). |
| `karpenter_instance_profile_name` | Nome do instance profile do Karpenter (ou `null`). |
| `karpenter_interruption_queue_name` | Nome da fila SQS de interrupcoes do Karpenter (ou `null`). |

## Exemplo

```hcl
module "eks" {
  source = "../../tf-modules/eks"

  cluster_name    = "lab-eks"
  aws_region      = "us-east-1"
  cluster_version = "1.35"
  allowed_azs     = ["us-east-1a", "us-east-1b"]

  # Deixe vazio para usar VPC/subnets default
  vpc_id     = ""
  subnet_ids = []
  fargate_subnet_ids = []

  enable_karpenter          = true
  enable_fargate_karpenter  = true
  karpenter_namespace       = "karpenter"
  karpenter_service_account = "karpenter"

  tags = {
    Environment = "dev"
    Lab         = "lab"
  }
}
```

## Exemplo de tfvars

```hcl
cluster_name = "eks-dev"
aws_region   = "us-east-1"
allowed_azs  = ["us-east-1a", "us-east-1b"]
vpc_id       = ""
subnet_ids   = []
fargate_subnet_ids = []

tags = {
  Environment = "dev"
  Lab         = "lab"
}
```
