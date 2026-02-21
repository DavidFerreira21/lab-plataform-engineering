# Plataforma (Helm + ArgoCD + Kind)

Esta pasta contém a camada de plataforma do lab: **GitOps com ArgoCD**, **charts Helm** e recursos para ambiente local com **Kind + Nginx Ingress**.

## Estrutura

```text
plataforma/
├── argo/
│   ├── application-kind.yaml # Application do ambiente Kind
│   ├── application-eks-core.yaml      # Crossplane core + metadata
│   ├── application-eks-instances.yaml # Claims de infra por app
│   ├── application-eks-workloads.yaml # Workloads (API + Web)
│   ├── ingress-kind.yaml     # Ingress do ArgoCD (Kind)
│   └── ingress-eks.yaml      # Ingress do ArgoCD (EKS)
├── bootstrap/                # Terraform bootstrap (raiz + módulos)
├── cluster-metadata/         # Chart app de metadados do cluster (External Secrets)
├── crossplane/               # Base + XRD + Compositions do Crossplane
├── minio/
│   └── minio.yaml             # MinIO local (S3 compatível)
└── helm-charts/
    ├── app-template/         # Chart base compartilhado pelas apps
    ├── crossplane-s3-claim/  # Chart base do claim S3 (Crossplane)
    ├── crossplane-irsa-claim/ # Chart base do claim IRSA
    └── external-secrets-ssm-metadata/ # SSM -> Secret (metadados do cluster)
```

## ArgoCD (GitOps)

### Application
Arquivos:
- `plataforma/argo/application-kind.yaml` (API + Web + MinIO)
- `plataforma/argo/application-eks-core.yaml` (Crossplane core + metadata)
- `plataforma/argo/application-eks-instances.yaml` (claims S3 + IRSA)
- `plataforma/argo/application-eks-workloads.yaml` (API + Web)
- Cada source possui `helm.releaseName` para evitar conflito de recursos
  - `platform-api` → recursos da API
  - `platform-web` → recursos da Web
  - `platform-storage-s3` → claims S3 + IRSA (instância unificada)
  - `platform-cluster-metadata` → External Secrets (SSM -> Secret)

### Ingress do ArgoCD
Arquivo: `plataforma/argo/ingress-kind.yaml`
- Host: `argocd.local`
- Nginx ingress class (Nginx Ingress Controller)
- SSL passthrough para o ArgoCD
- TLS via cert-manager (cluster-issuer + secret)

## Helm (chart base)

Chart base: `plataforma/helm-charts/app-template`
- Templates: `deployment.yaml`, `service.yaml`, `ingress.yaml`
- Template adicional: `hpa.yaml`
- Suporta:
  - `service.port` e `service.targetPort`
  - `service.name` (nome do Service)
  - `fullnameOverride`
  - `env` para variáveis de ambiente
  - `ingress.enabled` e `ingress.host`
  - `ingress.annotations` (ex.: `proxy-body-size`)
  - `ingress.tls` (cert-manager: issuer + secretName)
  - `probes.*` (readiness/liveness)
  - `resources` (requests/limits)
  - `hpa.*` (HorizontalPodAutoscaler)

## Dependências Helm (muito importante)

Os charts de `gitops/app` e `gitops/web` **vendorizam** o chart base em `gitops/*/charts/`.
Sempre que o chart base mudar, rode:

```bash
helm dependency build gitops/app
helm dependency build gitops/web
```

Depois commite:
- `gitops/app/Chart.lock`
- `gitops/web/Chart.lock`
- `gitops/app/charts/*.tgz`
- `gitops/web/charts/*.tgz`

Para os charts Crossplane de instância (GitOps), rode também:

```bash
helm dependency build gitops/storage-s3
helm dependency build plataforma/cluster-metadata
```

Depois commite:
- `gitops/storage-s3/Chart.lock`
- `gitops/storage-s3/charts/*.tgz`
- `plataforma/cluster-metadata/Chart.lock`
- `plataforma/cluster-metadata/charts/*.tgz`

## Crossplane S3/IRSA (automação)

Guia detalhado:
- `plataforma/crossplane/README.md`

Recursos de plataforma criados no GitOps:
- `plataforma/crossplane/xrd/irsa-xrd.yaml`
- `plataforma/crossplane/compositions/irsa.yaml`

Instâncias (claims) via Helm:
- `gitops/storage-s3` cria bucket S3 + IRSA no mesmo app.
- `plataforma/cluster-metadata` sincroniza do SSM para Secret (`cluster-aws-metadata`) via External Secrets.

Importante:
- O bucket é determinístico (nome definido no claim S3), então a policy já usa o nome esperado.
- Não é necessário informar OIDC no claim IRSA: a Composition lê os dados do `EnvironmentConfig` `cluster-aws-metadata`.
- O `EnvironmentConfig` é mantido no bootstrap Terraform com os valores reais do cluster EKS.

## Ambiente local (Kind + Nginx + ArgoCD)
O `makefile` na raiz automatiza o setup. A lista de comandos principais fica no `README.md` da raiz: [README.md](../README.md).

## Observações
- O Kind expõe portas 80/443 para o host via `kind-config.yaml`.
- Para acessar o ArgoCD localmente, use `argocd.local` (ajuste seu `/etc/hosts`).
- Para o Web, use o host definido em `gitops/web/values.yaml` (ex.: `web.local`).
- Para fork, edite o `repoURL` em `plataforma/argo/application-kind.yaml` com seu repositório
  - Ex.: `repoURL: 'https://github.com/seu-usuario/seu-repo.git'`

## MinIO (S3 local)
- Manifest: `plataforma/minio/minio.yaml`
- Service: `minio` na namespace `app` (porta 9000)
- Credenciais default (lab): `minioadmin` / `minioadmin`
- Bucket inicial: `carros` (criado via Job)
