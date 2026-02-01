# Lab de Platform Engineering (Monorepo API + Web)

Este repositório é um laboratório prático de **Platform Engineering** e **DevSecOps**. A ideia é evoluir do ciclo de build e segurança (CI) até **GitOps/CD**, IaC, runtime, observabilidade e governança.

## Contexto do Lab
- Monorepo com **API (FastAPI)** e **Web (Flask)**
- **CI** com SAST/SCA, build de imagens via Buildpacks e push para registry
- **CD GitOps** com **Helm + ArgoCD**
- Infra local com **Kind + Nginx Ingress**
- Storage local com **MinIO (S3 compatível)** para uploads

## Camadas atuais
- **CI/DevSecOps**: Bandit + Trivy + Buildpacks + push de imagens
- **CD/GitOps**: ArgoCD aplicando Helm Charts do monorepo
- **Infra local**: Kind com Nginx Ingress (via `makefile`)
- **Storage local**: MinIO para documentos de carros

## Roadmap (evolução do lab)
- Terraform para provisionar infra
- MongoDB Atlas criado via Terraform
- GitOps para Terraform com Terraform Controller
- Evolução até Backstage e fluxo completo de Platform Engineering

## Documentação detalhada
- Apps (API + Web): `app/README.md`
- Infra (Helm + ArgoCD + Kind): `infra/README.md`

## Arquitetura

```
[Browser] -> [Web Flask] -> [API FastAPI] -> [SQLite/Mongo]
```

GitOps/CD:
```
GitHub -> ArgoCD -> Helm -> Kubernetes
```

## Estrutura do repositório

```text
.
├── .github/workflows/         # Pipelines CI (API e Web)
├── app/
│   ├── api/                   # API FastAPI + Helm chart
│   └── web/                   # Web Flask + Helm chart
├── infra/
│   ├── argo/                  # Application + Ingress do ArgoCD
│   ├── minio/                 # MinIO local (S3 compatível)
│   └── charts/                # Helm chart base (app-template)
├── kind-config.yaml           # Cluster Kind com portas 80/443
├── makefile                   # Setup local (Kind, Nginx, ArgoCD)
└── README.md
```

## CI/CD (resumo)
- **CI**: pipelines por pasta (`app/api/**` e `app/web/**`) com Bandit, Trivy e Buildpacks
- **CD**: ArgoCD aplica `infra/argo/application.yaml` (via `make bootstrap-argo`) e sincroniza os Helm charts

## Funcionalidades recentes (destaques)
- Upload de documento do carro (Web → API → MinIO)
- Logs em JSON para stdout (API e Web)
- Probes de readiness/liveness via Helm values
- Service name configurável (`service.name`) no chart base

## Conceitos de segurança (explicações rápidas)
- **SAST (Static Application Security Testing)**: análise do código-fonte sem executar a aplicação; identifica padrões inseguros cedo no ciclo de desenvolvimento.
- **SCA (Software Composition Analysis)**: análise de dependências para detectar vulnerabilidades conhecidas em bibliotecas e pacotes.
- **Bandit**: ferramenta de SAST para Python; procura problemas comuns no código (ex.: binds inseguros, uso perigoso de funções).
- **Trivy**: scanner de SCA e de imagens de container; detecta CVEs em dependências e camadas de imagem.

## Decisões de monorepo (e trade-offs)
- **Pipelines por pasta**: API e Web têm workflows separados, mas vivem no mesmo repositório; isso simplifica o laboratório, porém em produção pode virar múltiplos repositórios para isolar ciclos de release.
- **Charts com dependência local**: usamos `file://` e vendorizamos `charts/*.tgz` no repo para facilitar o GitOps; em produção preferimos publicar o chart base em um repositório Helm.
- **ArgoCD com `sources` múltiplos**: uma única Application gerencia API e Web; em produção pode ser interessante separar Applications por serviço.

## Como rodar localmente (atalho)
- Infra/cluster: `make all` (ver detalhes em `infra/README.md`)
- Apps localmente: ver `app/README.md`

## Observações importantes
- Os charts de `app/api` e `app/web` usam o chart base `infra/charts/app-template` como dependência.
- Sempre que o chart base muda, é necessário rodar:
  - `helm dependency build app/api`
  - `helm dependency build app/web`
  - Commitar `Chart.lock` e `charts/*.tgz`

## Links rápidos
- App docs: `app/README.md`
- Infra docs: `infra/README.md`
