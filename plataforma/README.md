# Plataforma (ArgoCD + Crossplane + Terraform)

Esta pasta concentra a camada de plataforma do lab: bootstrap do cluster, catalogo de produtos de infraestrutura e fluxo GitOps.

## Estrutura

```text
plataforma/
├── argo/
├── bootstrap/
├── cluster-metadata/
├── crossplane/
├── helm-charts/
├── kyverno/
└── minio/
```

## Responsabilidade de cada diretorio
- `argo/`: AppProject e Applications por ambiente.
- `bootstrap/`: Terraform para EKS e add-ons base do cluster.
- `cluster-metadata/`: Helm chart com metadados do cluster consumidos via External Secrets.
- `crossplane/`: providers, XRDs e compositions dos produtos.
- `helm-charts/`: chart base de app + charts de claim Crossplane.
- `kyverno/`: politicas de validacao em modo `Audit`.
- `minio/`: storage local para fluxo Kind.

## GitOps com ArgoCD
### Kind
- Application: `platform-apps`.
- Conteudo: API + Web + MinIO.

### EKS
- `platform-core`: instala plataforma base (Crossplane + contratos + politicas).
- `garagem-infra`: cria instancias dos produtos (claims).
- `garagem-app`: publica os workloads da aplicacao.

Esse desenho reduz blast radius: erro em claim nao precisa bloquear sync de app, e vice-versa.

## Produtos Crossplane usados no lab
- `S3`: bucket + hardening + secret de conexao (`api-storage-conn`).
- `IRSA`: role/policy para service account da API.
- `RDS`: instancia PostgreSQL + Security Group e regra de ingress criados na composition.

## Governanca com Kyverno
Policies atuais:
- `disallow-latest-tag`
- `require-resources`
- `require-standard-labels`

Configuracao atual:
- `validationFailureAction: Audit`
- `emitWarning: true`

Com isso, deploy nao e bloqueado, mas warnings aparecem em eventos de `Deployment`/`ReplicaSet`.

## Operacao do dia a dia
### Reaplicar Applications
```bash
make bootstrap-argo PLATFORM=eks
```

### Forcar refresh no Argo
```bash
kubectl -n argocd annotate application platform-core argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd annotate application garagem-infra argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd annotate application garagem-app argocd.argoproj.io/refresh=hard --overwrite
```

### Atualizar dependencias Helm
```bash
make helm-build
```

## Troubleshooting rapido
- `OutOfSync` em `X*` (XR/XRDS/XS3/XIRSA): geralmente recurso gerado pelo Crossplane e nao manifesto fonte; validar app correta e prune.
- `secret ... not found`: verificar `writeConnectionSecretToRef` na composition e claim `Ready`.
- `InvalidIdentityToken` em pod: validar OIDC provider da conta, trust policy e annotation da ServiceAccount.
- `NoSuchBucket`: conferir `S3_BUCKET` vindo de `api-storage-conn` e status do claim S3.
