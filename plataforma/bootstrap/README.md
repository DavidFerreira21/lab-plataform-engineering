# Bootstrap (Terraform)

Esta pasta eh o **raiz do bootstrap** via Terraform. Aqui ficam as chamadas dos modulos que fazem o provisionamento.

## Estrutura

```text
plataforma/bootstrap/
├── crossplane.tf
├── data.tf
├── external-secrets.tf
├── main-eks.tf
├── providers.tf
├── outputs.tf
├── terraform.tfvars
├── variables.tf
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
terraform init -migrate-state -force-copy
terraform plan
terraform apply
```

## Backend de state (S3)
- O backend remoto do Terraform ja esta configurado em `providers.tf` usando S3.
- Bucket: `tfstate-terraform-lab-plataform-engineering`
- Key: `plataforma/bootstrap/terraform.tfstate`
- Regiao: `us-east-1`
- Lock de state: habilitado com `use_lockfile = true` (lock nativo no S3).
- DynamoDB: nao utilizado para lock neste bootstrap.
- O bucket deve existir antes do `terraform init` (no fluxo principal isso e feito por `make tf-backend-bootstrap` dentro de `make all-eks`).

## Variaveis principais (bootstrap)
- `aws_region` (default: `us-east-1`)
- `cluster_name` (default: `eks-dev`)
- `kubernetes_version` (default: `1.35`)
- `allowed_azs` (default: `us-east-1a, us-east-1b`)
- `use_default_vpc` (default: `true`; `true` usa VPC default, `false` exige `vpc_id` + `subnet_ids`)
- `cluster_security_group_ids` (lista, opcional)
- `public_access_cidrs` (lista, obrigatoria se `endpoint_public_access = true`)
- `cluster_log_types` (default: `api,audit,authenticator,controllerManager,scheduler`)
- `enable_encryption` (criptografia de secrets com KMS; quando `true`, o modulo cria a KMS automaticamente)
- `tags` (map)
- `update_max_unavailable` / `update_max_unavailable_percentage` (update do node group)
- `enable_addons` + `addon_versions` (padroes da console: vpc-cni, coredns, kube-proxy)
- `enable_cluster_creator_admin` / `cluster_creator_arn` / `access_entries` (acesso ao cluster via EKS Access)
- `enable_eks_oidc_provider` (ativa criacao do OIDC provider no `modules/eks` para uso por IRSA)
- `enable_crossplane` / `crossplane_namespace` / `crossplane_chart_version` (instalacao do Crossplane via Helm)
- `crossplane_environment_config_api_version` (apiVersion do `EnvironmentConfig`; default `apiextensions.crossplane.io/v1beta1`)
- `enable_crossplane_irsa` / `crossplane_irsa_namespace` / `crossplane_irsa_service_account` / `crossplane_irsa_role_name` (IRSA do provider-aws do Crossplane)
- `enable_crossplane_irsa_serviceaccount_sync` (anota o ServiceAccount do Crossplane automaticamente no cluster)
- `enable_external_secrets` / `external_secrets_namespace` / `external_secrets_chart_version` (instalacao do External Secrets via Helm)
- `enable_external_secrets_irsa` / `external_secrets_irsa_service_account` / `external_secrets_irsa_role_name` (IRSA do External Secrets para leitura de SSM)
- `enable_cluster_metadata_ssm` / `cluster_metadata_ssm_prefix` (grava metadados do cluster no SSM para automacoes futuras de IRSA)
- `node_instance_types` (default: `t3.medium`)
- `node_min_size`, `node_max_size`, `node_desired_size`
- `node_labels` (map)
- `node_taints` (lista de objetos)

Exemplo de `terraform.tfvars`:

```hcl
aws_region       = "us-east-1"
cluster_name     = "eks-dev"
allowed_azs      = ["us-east-1a", "us-east-1b"]
use_default_vpc  = true
public_access_cidrs = ["0.0.0.0/0"]
node_labels      = { workload = "tools" }
node_taints      = []
```

Observacao:
- Com `use_default_vpc = true`, o bootstrap usa VPC default e seleciona subnets por `allowed_azs`.
- Com `use_default_vpc = false`, e obrigatorio informar `vpc_id` e `subnet_ids` (minimo 2).
- Se `endpoint_public_access` for `true`, e obrigatorio informar `public_access_cidrs`.
- `access_entries` cria regras de acesso ao cluster sem precisar editar `aws-auth` manualmente.
- As roles IAM (`cluster_role_name` e `node_role_name`) passam a ser gerenciadas pelo Terraform. Se elas ja existirem fora do state, sera necessario fazer `terraform import`.
- Com `enable_eks_oidc_provider = true`, o bootstrap cria o OIDC provider do EKS para uso generico por IRSAs.
- Com `enable_crossplane = true`, o bootstrap instala o Crossplane no EKS via chart Helm.
- Com `enable_crossplane_irsa = true`, o bootstrap cria role IRSA para o ServiceAccount do Crossplane.
- O attach `PowerUserAccess` na IRSA do Crossplane e intencional neste ambiente de laboratorio. Em ambiente produtivo, substituir por policy de menor privilegio.
- Com `enable_crossplane_irsa_serviceaccount_sync = true`, o bootstrap cria/sincroniza Namespace + ServiceAccount e aplica a annotation `eks.amazonaws.com/role-arn` automaticamente.
- Com `enable_external_secrets = true`, o bootstrap instala o chart `external-secrets` no cluster EKS e aplica `installCRDs=true`.
- Com `enable_external_secrets_irsa = true`, o bootstrap cria IRSA de menor privilegio para o ServiceAccount do External Secrets (leitura de parametros em `/<prefix>/<cluster_name>/*`).
- Com `enable_cluster_metadata_ssm = true`, o bootstrap grava parametros no SSM em `/<prefix>/<cluster_name>/...` (issuer OIDC, hostpath, provider ARN, account ID, etc.).

## Arquivos principais
- `main-eks.tf`: chamada do modulo EKS e resolucao de VPC/subnets.
- `providers.tf`: providers e backend remoto S3 do Terraform state.
- `crossplane.tf`: instalacao do Crossplane via Helm + IRSA do Crossplane (AWS/Kubernetes).
- `data.tf`: data sources centralizados (rede, autenticacao EKS e policy docs IAM).
- `external-secrets.tf`: instalacao do External Secrets via Helm.
- `ssm-parameters.tf`: publicacao de metadados do cluster no SSM Parameter Store.

Observacao tecnica:
- Endpoint/CA/OIDC do cluster sao consumidos via outputs do modulo `eks` (sem `data.aws_eks_cluster` na raiz).
- O data source `aws_eks_cluster_auth` permanece para obter token dinamico dos providers `kubernetes` e `helm`.
