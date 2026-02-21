# Lab de Platform Engineering (Monorepo API + Web)

Este repositorio e um laboratorio pratico de **Platform Engineering** e **DevSecOps**.
O fluxo cobre CI, GitOps, infraestrutura em EKS e produtos de plataforma com Crossplane.

## Contexto do lab
- Monorepo com **API (FastAPI)** e **Web (Flask)**
- **CI** com Ruff, Black, Pytest, Bandit, Trivy e Buildpacks
- **CD GitOps** com ArgoCD aplicando Helm charts do proprio repositorio
- Ambientes:
  - **Kind** (local): apps + MinIO
  - **EKS** (AWS): Crossplane + claims S3/IRSA + workloads

## Camadas atuais
- **Apps**: `app/api` e `app/web`
- **GitOps**: `plataforma/argo` + `gitops/*`
- **Bootstrap IaC**: `plataforma/bootstrap` (Terraform)
- **Platform API**: `plataforma/crossplane` (XRD + Composition)
- **Policy as Code**: `plataforma/kyverno` (modo Audit com warnings)

## Estrutura do repositorio

```text
.
├── .github/workflows/
├── app/
│   ├── api/
│   └── web/
├── gitops/
│   ├── app/
│   ├── web/
│   └── storage-s3/
├── plataforma/
│   ├── argo/
│   ├── bootstrap/
│   ├── cluster-metadata/
│   ├── crossplane/
│   ├── helm-charts/
│   ├── kyverno/
│   └── minio/
├── kind-config.yaml
├── makefile
└── README.md
```

## ArgoCD por ambiente
- **Kind**: 1 app (`platform-apps`) com API + Web + MinIO.
- **EKS**: 3 apps desacopladas:
  - `platform-core` (Crossplane base/xrd/compositions + cluster metadata + kyverno)
  - `garagem-infra` (claims S3/IRSA/RDS)
  - `garagem-app` (API + Web)

## Make targets principais
- `make all-kind`: sobe stack local completa (Kind + ingress + Argo + GitOps)
- `make all-eks`: bootstrap EKS (Terraform), helm dependencies e bootstrap GitOps
- `make cluster-eks`: init/apply Terraform + kubecontext
- `make bootstrap-argo PLATFORM=kind|eks`: aplica apps do Argo para cada ambiente
- `make helm-build`: atualiza dependencies Helm dos charts usados no GitOps
- `make down` / `make down-eks`: teardown local / AWS

## Fluxo EKS (resumo)
1. Terraform cria/atualiza EKS (`module.eks`).
2. Terraform instala add-ons (`module.addons`): Crossplane, External Secrets, ArgoCD, ingress-nginx, Kyverno (via flags).
3. `bootstrap-argo PLATFORM=eks` aplica as 3 Applications.
4. Claims Crossplane provisionam S3 + IRSA.
5. API consome `S3_BUCKET` via secret de conexao (`api-storage-conn`).

## Documentacao detalhada
- Apps: `app/README.md`
- Plataforma: `plataforma/README.md`
- Bootstrap Terraform: `plataforma/bootstrap/README.md`
- Crossplane: `plataforma/crossplane/README.md`

## Observacoes
- O chart base das apps e compartilhado em `plataforma/helm-charts/app-template`.
- Sempre que um chart base mudar, rode `make helm-build` e commite `Chart.lock` + `charts/*.tgz`.
