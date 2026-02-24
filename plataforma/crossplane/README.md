# Crossplane (catalogo de produtos da plataforma)

Este diretorio define contratos e implementacoes dos produtos de infraestrutura usados pelo lab.

## Estrutura
- `base/`: instalacao base do Crossplane (providers, runtime config, functions, provider-config).
- `xrd/`: contratos de produto (XRDs).
- `compositions/`: implementacao AWS de cada produto.

## Produtos disponiveis
- Python App Infra (`XPythonAppInfra`) - contrato unico

## Ordem de sync no Argo (`platform-core`)
- `-2`: namespace/base runtime
- `-1`: providers e functions
- `0`: provider config
- `1`: XRDs
- `2`: compositions

## Base instalada (`base/`)
- Functions:
  - `function-environment-configs`
  - `function-patch-and-transform`
- Providers AWS:
  - `provider-aws-s3`
  - `provider-aws-iam`
  - `provider-aws-rds`
  - `provider-aws-ec2`
  - `provider-kubernetes`
- RuntimeConfig:
  - `aws-irsa`

## Contrato unico (XPythonAppInfra)
Arquivos:
- `xrd/python-app-infra-xrd.yaml`
- `compositions/python-app-infra.yaml`

Implementacao criada por uma unica instancia:
- S3 Bucket + encryption + versioning + public access block
- IAM Role/Policy/Attachment para IRSA
- ServiceAccount anotada com role ARN (via provider-kubernetes)
- SecurityGroup + SecurityGroupRule para banco
- RDS PostgreSQL Instance
- Secret de conexao do S3 e secret de conexao do banco

## Integracao com workloads
Contrato no `garagem-infra`:
- `XPythonAppInfra` -> cria S3, IRSA, ServiceAccount anotada, RDS, SG/Rule e secrets de conexao usados pela API.

Segredos esperados no namespace da app:
- `api-storage-conn` (bucketName)
- `api-garagem-db-conn` (host/port/username/database)
- `api-garagem-db-auth` (password)

A API em `gitops/app/values-eks.yaml` consome esses secrets por `valueFrom.secretKeyRef`.

## Padroes adotados no lab
- Nome de bucket S3 deterministico por conta (evita colisao entre contas).
- `deletionPolicy` default dos produtos sensiveis em `Orphan` para evitar perda acidental.
- Reconciliacao declarativa: app nao descobre nome de recurso em runtime; recebe via secret.

## Troubleshooting rapido
- Provider nao sobe:
```bash
kubectl get providers.pkg.crossplane.io
kubectl get providerrevision.pkg.crossplane.io
```

- `XPythonAppInfra` nao fica `Ready`:
```bash
kubectl get xpythonappinfras.platform.lab
kubectl get xpythonappinfras.platform.lab <nome> -o yaml
```

- Erro de IRSA (`InvalidIdentityToken` / `AccessDenied`):
1. validar issuer do cluster
2. validar OIDC provider na conta ativa
3. validar trust policy da role
4. validar annotation da service account usada no deploy

- Erro S3 `NoSuchBucket`:
1. validar `XPythonAppInfra` em `Ready`
2. validar secret `api-storage-conn`
3. validar env `S3_BUCKET` no deployment
