# Bootstrap (Terraform)

Esta pasta eh o **raiz do bootstrap** via Terraform. Aqui ficam as chamadas dos modulos que fazem o provisionamento.

## Estrutura

```text
plataforma/bootstrap/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
└── modules/
    └── eks/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Modulos
- `modules/eks`: provisiona um cluster EKS com Node Group e roles IAM. A VPC default eh selecionada na raiz, mas o modulo aceita qualquer VPC.

## Uso rapido

```bash
cd plataforma/bootstrap
terraform init
terraform plan
terraform apply
```

## Variaveis principais
- `aws_region` (default: `us-east-1`)
- `cluster_name` (default: `eks-dev`)
- `kubernetes_version` (default: `1.35`)
- `allowed_azs` (default: `us-east-1a, us-east-1b`)
- `cluster_security_group_ids` (lista, opcional)
- `public_access_cidrs` (lista, obrigatoria se `endpoint_public_access = true`)
- `cluster_log_types` (default: `api,audit,authenticator,controllerManager,scheduler`)
- `enable_encryption` + `kms_key_arn` (criptografia de secrets com KMS; se `kms_key_arn` estiver vazio, o modulo cria a KMS automaticamente)
- `tags` (map)
- `update_max_unavailable` / `update_max_unavailable_percentage` (update do node group)
- `enable_addons` + `addon_versions` (vpc-cni, coredns, kube-proxy)
- `enable_cluster_creator_admin` / `cluster_creator_arn` / `access_entries` (acesso ao cluster via EKS Access)
- `node_instance_types` (default: `t3.medium`)
- `node_min_size`, `node_max_size`, `node_desired_size`
- `node_labels` (map)
- `node_taints` (lista de objetos)

Exemplo de `terraform.tfvars`:

```hcl
aws_region       = "us-east-1"
cluster_name     = "eks-dev"
allowed_azs      = ["us-east-1a", "us-east-1b"]
public_access_cidrs = ["0.0.0.0/0"]
node_labels      = { workload = "tools" }
node_taints      = []
```

Observacao:
- A **VPC default** eh escolhida no codigo principal quando `vpc_id` nao eh informado.
- O modulo aceita qualquer VPC via `vpc_id` e `subnet_ids` e requer pelo menos 2 subnets.
- Se `endpoint_public_access` for `true`, e obrigatorio informar `public_access_cidrs`.
- `access_entries` cria regras de acesso ao cluster sem precisar editar `aws-auth` manualmente.
- As roles IAM (`cluster_role_name` e `node_role_name`) passam a ser gerenciadas pelo Terraform. Se elas ja existirem fora do state, sera necessario fazer `terraform import`.
