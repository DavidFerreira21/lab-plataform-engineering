# Plataforma (Helm + ArgoCD + Kind)

Esta pasta contém a camada de plataforma do lab: **GitOps com ArgoCD**, **charts Helm** e recursos para ambiente local com **Kind + Nginx Ingress**.

## Estrutura

```text
plataforma/
├── argo/
│   ├── application.yaml      # Application com múltiplas sources (API e Web)
│   └── ingress.yaml          # Ingress do ArgoCD
├── minio/
│   └── minio.yaml             # MinIO local (S3 compatível)
└── charts/
    └── app-template/         # Chart base compartilhado pelas apps
```

## ArgoCD (GitOps)

### Application
Arquivo: `plataforma/argo/application.yaml`
- Usa `sources` (plural) para API, Web e MinIO
- Cada source possui `helm.releaseName` para evitar conflito de recursos
  - `platform-api` → recursos da API
  - `platform-web` → recursos da Web

### Ingress do ArgoCD
Arquivo: `plataforma/argo/ingress.yaml`
- Host: `argocd.local`
- Nginx ingress class (Nginx Ingress Controller)
- SSL passthrough para o ArgoCD
- TLS via cert-manager (cluster-issuer + secret)

## Helm (chart base)

Chart base: `plataforma/charts/app-template`
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

## Ambiente local (Kind + Nginx + ArgoCD)
O `makefile` na raiz automatiza o setup. A lista de comandos principais fica no `README.md` da raiz: [README.md](../README.md).

## Observações
- O Kind expõe portas 80/443 para o host via `kind-config.yaml`.
- Para acessar o ArgoCD localmente, use `argocd.local` (ajuste seu `/etc/hosts`).
- Para o Web, use o host definido em `gitops/web/values.yaml` (ex.: `web.local`).
- Para fork, edite o `repoURL` em `plataforma/argo/application.yaml` com seu repositório
  - Ex.: `repoURL: 'https://github.com/seu-usuario/seu-repo.git'`

## MinIO (S3 local)
- Manifest: `plataforma/minio/minio.yaml`
- Service: `minio` na namespace `app` (porta 9000)
- Credenciais default (lab): `minioadmin` / `minioadmin`
- Bucket inicial: `carros` (criado via Job)
