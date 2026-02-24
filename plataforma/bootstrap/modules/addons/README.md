# Module Addons

Modulo Terraform para instalar add-ons de cluster e integrar IAM/IRSA da plataforma.

## Responsabilidades do modulo
- Instalar add-ons via Helm com flags de enable.
- Criar IRSA do Crossplane provider.
- Criar IRSA do External Secrets.
- Publicar `EnvironmentConfig` (`cluster-aws-metadata`) com contexto dinamico da conta/cluster.

## Add-ons suportados
- Crossplane
- External Secrets
- Argo CD
- ingress-nginx
- Kyverno

## Arquivos
- `data.tf`: data sources e locals.
- `main.tf`: IAM, Helm releases e manifests Kubernetes.
- `variables.tf`: interface do modulo.
- `outputs.tf`: outputs de releases e ARNs.

## Inputs principais
- `cluster_name`
- `cluster_oidc_issuer`
- `oidc_provider_arn`
- `cluster_vpc_id`
- flags `enable_*` dos add-ons

## EnvironmentConfig publicado
Recurso: `kubernetes_manifest.crossplane_environment_config`

Campos publicados em `data`:
- `accountId`
- `oidcProviderArn`
- `oidcIssuerHostpath`
- `vpcId`
- `vpcCidrBlock`

Esses campos sao consumidos pelas Compositions (ex.: trust policy IRSA e SG/regra de rede do RDS).

## Recursos importantes
### Crossplane
- `helm_release.crossplane`
- `aws_iam_role.crossplane_irsa`
- `aws_iam_role_policy_attachment.crossplane_irsa_poweruser`
- `aws_iam_role_policy_attachment.crossplane_irsa_iam_full_access` (opcional)
- `kubernetes_manifest.crossplane_irsa_serviceaccount`
- `kubernetes_manifest.crossplane_environment_config`

### External Secrets
- `helm_release.external_secrets`
- `aws_iam_role.external_secrets_irsa`
- `aws_iam_policy.external_secrets_ssm_read`
- `aws_iam_role_policy_attachment.external_secrets_irsa_ssm_read`
- `kubernetes_manifest.external_secrets_cluster_secret_store` (`aws-secretsmanager`)

### Outros add-ons
- `helm_release.argocd`
- `helm_release.ingress_nginx`
- `helm_release.kyverno`

## Outputs
- `crossplane_release_name`
- `crossplane_irsa_role_arn`
- `external_secrets_release_name`
- `external_secrets_irsa_role_arn`
- `argocd_release_name`
- `ingress_nginx_release_name`
- `kyverno_release_name`

## Notas operacionais
- Em lab, `PowerUserAccess` + `IAMFullAccess` acelera experimentacao.
- Em producao, substitua por politicas minimas por provider/recurso.
- O `EnvironmentConfig` so deve ser aplicado apos CRDs/funcoes do Crossplane estarem prontas.

## Troubleshooting
- `no matches for kind EnvironmentConfig`: Crossplane/CRD ainda nao instalado.
- Provider em `Progressing` por muito tempo: validar namespace `crossplane-system` e `DeploymentRuntimeConfig` (`aws-irsa`).
- `InvalidIdentityToken` em app: geralmente OIDC/trust policy fora da conta alvo.
