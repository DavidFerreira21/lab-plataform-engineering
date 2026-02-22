# Crossplane (catalogo de produtos da plataforma)

Este diretorio define contratos e implementacoes dos produtos de infraestrutura usados pelo lab.

## Estrutura
- `base/`: instalacao base do Crossplane (providers, runtime config, functions, provider-config).
- `xrd/`: contratos de produto (XRDs e claims).
- `compositions/`: implementacao AWS de cada produto.

## Produtos disponiveis
- S3 (`XS3`)
- IRSA (`XIRSA`)
- RDS (`XRDS`)

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
- RuntimeConfig:
  - `aws-irsa`

## Produto S3
Arquivos:
- `xrd/s3-xrd.yaml`
- `compositions/s3.yaml`

Implementacao:
- Bucket
- BucketPublicAccessBlock
- BucketServerSideEncryptionConfiguration
- BucketVersioning

Conexao publicada:
- `bucketName`
- `bucketArn`

## Produto IRSA
Arquivos:
- `xrd/irsa-xrd.yaml`
- `compositions/irsa.yaml`

Implementacao:
- IAM Policy
- IAM Role
- RolePolicyAttachment

A trust policy e montada dinamicamente usando dados do `EnvironmentConfig` (`oidcProviderArn`, `oidcIssuerHostpath`).

## Produto RDS
Arquivos:
- `xrd/rds-xrd.yaml`
- `compositions/rds.yaml`

Implementacao:
- EC2 SecurityGroup
- EC2 SecurityGroupRule (ingress 5432 com `vpcCidrBlock`)
- RDS Instance associada ao SG criado na propria composition

Conexao publicada:
- `host`
- `port`
- `username`
- `database`

## Integracao com workloads
XRs sao aplicados em `gitops/storage-s3` (app `garagem-infra`):
- `XS3` -> bucket S3
- `XIRSA` -> role/policy para service account
- `XRDS` -> banco e secret de conexao (`api-garagem-db-conn`)

No Crossplane v2, secret de conexao de XR/claim nao e suportado.
Por isso o `api-storage-conn` e gerado via `ExternalSecret` no app `platform-core`, usando `accountId` do SSM.

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

- Claim nao fica `Ready`:
```bash
kubectl -n app get <claim-kind> <claim-name> -o yaml
kubectl -n app get x<claim-kind> -l crossplane.io/claim-name=<claim-name> -o yaml
```

- Erro de IRSA (`InvalidIdentityToken` / `AccessDenied`):
1. validar issuer do cluster
2. validar OIDC provider na conta ativa
3. validar trust policy da role
4. validar annotation da service account usada no deploy

- Erro S3 `NoSuchBucket`:
1. validar claim S3 `Ready`
2. validar secret `api-storage-conn`
3. validar env `S3_BUCKET` no deployment
