# Bootstrap (Terraform)

Diretorio de bootstrap AWS/EKS do lab. Aqui ficam rede, cluster e add-ons base necessarios antes do GitOps aplicar produtos e workloads.

## Estrutura

```text
plataforma/bootstrap/
├── addons.tf
├── data.tf
├── main-eks.tf
├── outputs.tf
├── providers.tf
├── variables.tf
└── modules/
    ├── eks/
    └── addons/
```

## Modulos
- `modules/eks`: cluster EKS, node group, addons gerenciados da AWS, OIDC provider.
- `modules/addons`: Helm add-ons (Crossplane, External Secrets, ArgoCD, ingress-nginx, Kyverno) + IRSA de plataforma.

## Add-ons controlados por flags
- `enable_crossplane`
- `enable_external_secrets`
- `enable_argocd`
- `enable_ingress_nginx`
- `enable_kyverno`

## Pre-requisitos
- Terraform instalado.
- AWS CLI autenticado na conta alvo.
- Permissao para criar IAM, EKS, EC2 e Helm releases via provider Kubernetes.

## Fluxo rapido
```bash
cd plataforma/bootstrap
terraform init -reconfigure
terraform plan
terraform apply
```

## Fluxo usado no `make all-eks`
O target `tf-eks-apply` executa em 3 fases para evitar corrida de CRDs:
1. `terraform apply -target=module.eks`
2. `terraform apply -target=module.addons.helm_release.crossplane`
3. `terraform apply` completo

## Backend remoto
Configurado em `providers.tf`:
- state em S3
- `use_lockfile = true`

O bucket de state pode ser criado por:
```bash
make tf-backend-bootstrap
```

## Metadados de cluster para plataforma
Os metadados de conta/cluster sao publicados diretamente como `EnvironmentConfig`
no modulo `addons` (recurso `crossplane_environment_config`), que e a unica
fonte de verdade consumida pelas Compositions.

## Observacoes praticas
- Em EKS deste lab, ArgoCD e instalado via Terraform (`enable_argocd=true`).
- `bootstrap-argo PLATFORM=eks` depois aplica apenas as Applications.
- Se IRSA falhar apos trocar de conta, valide na ordem:
1. `aws sts get-caller-identity`
2. OIDC issuer do cluster
3. annotation da service account
4. trust policy da role

## Comandos uteis
```bash
# contexto kubectl do cluster criado
make eks-configure-context

# outputs principais
cd plataforma/bootstrap && terraform output
```
