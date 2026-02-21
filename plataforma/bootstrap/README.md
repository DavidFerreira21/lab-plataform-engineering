# Bootstrap (Terraform)

Pasta raiz do bootstrap Terraform para EKS e add-ons.

## Estrutura

```text
plataforma/bootstrap/
├── addons.tf
├── data.tf
├── main-eks.tf
├── outputs.tf
├── providers.tf
├── ssm-parameters.tf
├── terraform.tfvars
├── variables.tf
└── modules/
    ├── eks/
    │   └── README.md
    └── addons/
        ├── data.tf
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── README.md
```

## Modulos
- `modules/eks`: cluster EKS, node group, addons EKS managed e OIDC provider.
- `modules/addons`: Helm addons + IAM IRSA para componentes de plataforma.

## Add-ons suportados (flags)
- `enable_crossplane`
- `enable_external_secrets`
- `enable_argocd`
- `enable_ingress_nginx`
- `enable_kyverno`

## Fluxo rapido
```bash
cd plataforma/bootstrap
terraform init -reconfigure
terraform plan
terraform apply
```

## Fluxo usado no make (`make all-eks`)
O target `tf-eks-apply` executa em 3 fases:
1. `terraform apply -target=module.eks`
2. `terraform apply -target=module.addons.helm_release.crossplane`
3. `terraform apply` completo

Isso reduz erros de dependencia de CRDs do Crossplane no primeiro bootstrap.

## Backend remoto
- S3 backend definido em `providers.tf`
- lockfile nativo no S3 (`use_lockfile = true`)
- bucket de state criado por `make tf-backend-bootstrap`

## Metadados de cluster (SSM)
`ssm-parameters.tf` grava dados em SSM para uso por automacoes:
- account id
- cluster name/region
- OIDC issuer
- OIDC hostpath
- OIDC provider ARN

Esses dados sao consumidos no cluster via External Secrets -> `EnvironmentConfig` do Crossplane.

## Observacoes praticas
- Para EKS deste lab, o ArgoCD e instalado via Terraform (`enable_argocd=true`) e o `bootstrap-argo PLATFORM=eks` aplica somente as Applications.
- Se OIDC/IRSA quebrar ao trocar de conta, validar primeiro `aws sts get-caller-identity`, issuer do cluster e annotation da service account.
