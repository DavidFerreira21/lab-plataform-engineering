# Module Addons

Modulo Terraform para instalar e integrar add-ons no cluster EKS.

## O que o modulo faz
- Instala add-ons via Helm (com flags de enable)
- Cria IRSA para Crossplane provider
- Cria IRSA para External Secrets
- Publica `EnvironmentConfig` no Crossplane com dados dinamicos da conta/cluster

## Add-ons suportados
- Crossplane
- External Secrets
- Argo CD
- ingress-nginx
- Kyverno

## Arquivos
- `data.tf`: data sources e locals (ex.: `oidc_issuer_hostpath`)
- `main.tf`: recursos IAM + Helm releases + manifests Kubernetes
- `variables.tf`: entradas/flags do modulo
- `outputs.tf`: nomes de releases e ARNs principais

## Inputs principais
- `cluster_name`
- `cluster_oidc_issuer`
- `oidc_provider_arn`
- `enable_eks_oidc_provider`
- flags:
  - `enable_crossplane`
  - `enable_external_secrets`
  - `enable_argocd`
  - `enable_ingress_nginx`
  - `enable_kyverno`

## Recursos importantes

### Crossplane
- `helm_release.crossplane`
- `aws_iam_role.crossplane_irsa`
- `kubernetes_manifest.crossplane_irsa_serviceaccount`
- `kubernetes_manifest.crossplane_environment_config`

### External Secrets
- `helm_release.external_secrets`
- `aws_iam_role.external_secrets_irsa`
- `aws_iam_policy.external_secrets_ssm_read`

### Demais add-ons
- `helm_release.argocd`
- `helm_release.ingress_nginx`
- `helm_release.kyverno`

## Saidas
- `crossplane_release_name`
- `crossplane_irsa_role_arn`
- `external_secrets_release_name`
- `external_secrets_irsa_role_arn`
- `argocd_release_name`
- `ingress_nginx_release_name`
- `kyverno_release_name`

## Observacoes
- Em laboratorio, a role IRSA do Crossplane pode receber `PowerUserAccess` e opcionalmente `IAMFullAccess`.
- Em producao, substituir por politicas de menor privilegio.
- O `EnvironmentConfig` depende do Crossplane instalado e do OIDC provider habilitado.
