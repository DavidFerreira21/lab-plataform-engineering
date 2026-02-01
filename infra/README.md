# Infra (Helm + ArgoCD + Kind)

Esta pasta contém a camada de infra do lab: **GitOps com ArgoCD**, **charts Helm** e recursos para ambiente local com **Kind + Nginx Ingress**.

## Estrutura

```text
infra/
├── argo/
│   ├── application.yaml      # Application com múltiplas sources (API e Web)
│   └── ingress.yaml          # Ingress do ArgoCD
├── minio/
│   └── minio.yaml             # MinIO local (S3 compatível)
└── charts/
    └── app-template/         # Chart base compartilhado pelas apps
```

## Arquitetura (Infra/GitOps)

```mermaid
flowchart LR
  Dev[Dev / Git Commit] --> GH[GitHub Repo]
  GH -->|Sync| Argo[ArgoCD]
  Argo -->|Helm render/apply| K8s[Kubernetes (Kind)]
  K8s --> Web[Service Web + Ingress]
  K8s --> API[Service API]
  Ingress[Nginx Ingress] --> Web
  ArgoUI[ArgoCD UI] --> Argo
```

## ArgoCD (GitOps)

### Application
Arquivo: `infra/argo/application.yaml`
- Usa `sources` (plural) para API, Web e MinIO
- Cada source possui `helm.releaseName` para evitar conflito de recursos
  - `platform-api` → recursos da API
  - `platform-web` → recursos da Web

### Ingress do ArgoCD
Arquivo: `infra/argo/ingress.yaml`
- Host: `argocd.local`
- Nginx ingress class
- SSL passthrough para o ArgoCD

## Helm (chart base)

Chart base: `infra/charts/app-template`
- Templates: `deployment.yaml`, `service.yaml`, `ingress.yaml`
- Suporta:
  - `service.port` e `service.targetPort`
  - `service.name` (nome do Service)
  - `fullnameOverride`
  - `env` para variáveis de ambiente
  - `ingress.enabled` e `ingress.host`
  - `ingress.annotations` (ex.: `proxy-body-size`)
  - `probes.*` (readiness/liveness)

## Dependências Helm (muito importante)

Os charts de `app/api` e `app/web` **vendorizam** o chart base em `app/*/charts/`.
Sempre que o chart base mudar, rode:

```bash
helm dependency build app/api
helm dependency build app/web
```

Depois commite:
- `app/api/Chart.lock`
- `app/web/Chart.lock`
- `app/api/charts/*.tgz`
- `app/web/charts/*.tgz`

## Ambiente local (Kind + Nginx + ArgoCD)

O `makefile` na raiz automatiza o setup:

```bash
make all
```

Comandos úteis:
- `make setup` instala Docker/Kubectl/Kind/Helm
- `make cluster` cria o cluster Kind (usa `kind-config.yaml`)
- `make install-nginx` instala o Nginx Ingress
- `make install-argo` instala o ArgoCD
- `make bootstrap-argo` aplica Application e Ingress do ArgoCD
- `make status` mostra status do cluster
- `make down` remove o cluster

## Observações
- O Kind expõe portas 80/443 para o host via `kind-config.yaml`.
- Para acessar o ArgoCD localmente, use `argocd.local` (ajuste seu `/etc/hosts`).
- Para o Web, use o host definido em `app/web/values.yaml` (ex.: `web.local`).
- Para fork, edite o `repoURL` em `infra/argo/application.yaml` com seu repositório

## MinIO (S3 local)
- Manifest: `infra/minio/minio.yaml`
- Service: `minio` na namespace `app` (porta 9000)
- Credenciais default (lab): `minioadmin` / `minioadmin`
- Bucket inicial: `carros` (criado via Job)
