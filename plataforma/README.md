# Plataforma (Helm + ArgoCD + Crossplane)

Esta pasta contem a camada de plataforma do lab: GitOps, componentes de plataforma e bootstrap.

## Estrutura

```text
plataforma/
├── argo/
│   ├── application-kind.yaml
│   ├── application-eks-core.yaml
│   ├── application-eks-instances.yaml
│   ├── application-eks-workloads.yaml
│   ├── ingress-kind.yaml
│   └── ingress-eks.yaml
├── bootstrap/
├── cluster-metadata/
├── crossplane/
├── helm-charts/
├── kyverno/
└── minio/
```

## ArgoCD (GitOps)

### Kind
- `platform-apps`: API + Web + MinIO.

### EKS
- `platform-core`:
  - `plataforma/crossplane/base`
  - `plataforma/crossplane/xrd`
  - `plataforma/crossplane/compositions`
  - `plataforma/cluster-metadata`
  - `plataforma/kyverno`
- `garagem-infra`:
  - `gitops/storage-s3` (claims S3 + IRSA + RDS)
- `garagem-app`:
  - `gitops/app`
  - `gitops/web`

Essa separacao reduz acoplamento e facilita troubleshooting por camada.

## Crossplane + claims
- Definicoes de produto em `plataforma/crossplane`
- Instancias em `gitops/storage-s3`
- Secret de conexao do bucket: `api-storage-conn`
- API usa `S3_BUCKET` vindo desse secret em EKS

## Kyverno
Pasta: `plataforma/kyverno`

Policies atuais (ClusterPolicy):
- `disallow-latest-tag`
- `require-resources`
- `require-standard-labels`

Configuracao:
- `validationFailureAction: Audit`
- `emitWarning: true`

Comportamento esperado:
- nao bloqueia deploy
- warnings aparecem no `kubectl apply`, e em eventos de Deployment/ReplicaSet

## Helm chart base
Chart base compartilhado: `plataforma/helm-charts/app-template`

Se alterar chart base, rode:
```bash
make helm-build
```

e commite `Chart.lock` + `charts/*.tgz` dos charts impactados.

## MinIO (local)
- Manifest: `plataforma/minio/minio.yaml`
- Usado no fluxo Kind
- Em EKS o storage e S3 via Crossplane
