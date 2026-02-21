# Crossplane (S3 + IRSA + RDS)

Este diretorio define os produtos de plataforma no Crossplane.

## Estrutura
- `base/`: install, providers, runtime config, function, provider config
- `xrd/`: contratos (`S3`, `IRSA`, `RDS`)
- `compositions/`: implementacao AWS

## Ordem de sync (Argo)
- `-2`: namespace/runtime base
- `-1`: providers + functions
- `0`: provider config
- `1`: XRDs
- `2`: compositions
- `3/4`: claims (app `garagem-infra`)

## Produto S3
- XRD: `xrd/s3-xrd.yaml`
- Composition: `compositions/s3.yaml`

A composicao cria:
- Bucket
- BucketPublicAccessBlock
- BucketServerSideEncryptionConfiguration
- BucketVersioning

Tambem publica dados de conexao (`bucketName`, `bucketArn`) para secret.

## Produto IRSA
- XRD: `xrd/irsa-xrd.yaml`
- Composition: `compositions/irsa.yaml`

A composicao cria:
- IAM Policy
- IAM Role
- IAM RolePolicyAttachment

OIDC e lido dinamicamente do `EnvironmentConfig` `cluster-aws-metadata`.

## Produto RDS
- XRD: `xrd/rds-xrd.yaml`
- Composition: `compositions/rds.yaml`

A composicao cria:
- `SecurityGroup` (EC2)
- `SecurityGroupRule` de ingress para a VPC
- `Instance` (RDS) associada ao SG criado na composicao

Parametros principais no claim:
- `engine` / `engineVersion`
- `instanceClass`
- `allocatedStorage`
- `dbName`
- `username`
- `passwordSecretName` / `passwordSecretNamespace`

Saida de conexao:
- `host`
- `port`
- `username`
- `database`

## Integracao com apps
- Claims ficam em `gitops/storage-s3`
- `S3` claim usa `connectionSecretName: api-storage-conn`
- API (chart `gitops/app/values-eks.yaml`) le `S3_BUCKET` desse secret
- `RDS` claim usa `connectionSecretName: api-garagem-db-conn`

## Convencao de bucket
No estado atual da composicao S3, o nome externo do bucket segue:
- `api-storage-us-east-1-<accountId>`

Isso evita fixar account id manualmente no git.

## Troubleshooting rapido
- Provider nao sobe:
  - `kubectl get providers.pkg.crossplane.io`
  - `kubectl get providerrevision.pkg.crossplane.io`
- Claim IRSA nao fica Ready:
  - validar `EnvironmentConfig cluster-aws-metadata`
  - validar CRDs/functions instaladas
- Upload da API falha com `NoSuchBucket`:
  - validar `S3_BUCKET` vindo de `api-storage-conn`
  - validar status do claim `s3.platform.lab`
