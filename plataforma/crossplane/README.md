# Crossplane (S3 + IRSA)

Este diretório contém a definição da camada de plataforma no Crossplane.

## O que existe aqui

- `base/`: componentes base do Crossplane (namespace, providers, provider config e function).
- `xrd/`: contratos de produto (`S3` e `IRSA`).
- `compositions/`: implementação de cada produto em recursos AWS.

## Ordem de sincronização (ArgoCD)

- `-2`: namespace/runtime base (`crossplane-system`, runtime config).
- `-1`: providers e function.
- `0`: `ProviderConfig`.
- `1`: XRDs (`S3`, `IRSA`).
- `2`: Compositions.
- `3/4`: claims de instância (via app GitOps `gitops/storage-s3`).

## Providers e credenciais

Arquivos em `base/`:

- `install.yaml`: namespace `crossplane-system`.
- `provider-aws-s3.yaml`: provider AWS S3.
- `provider-aws-iam.yaml`: provider AWS IAM.
- `provider-runtimeconfig-aws-irsa.yaml`: runtime com service account fixo `provider-aws`.
- `provider-config.yaml`: `ProviderConfig` padrão com `credentials.source: IRSA`.
- `function-patch-and-transform.yaml`: function para Compositions em `mode: Pipeline`.

Observação:
- A role IRSA do provider é aplicada pelo bootstrap Terraform no service account.

## Produtos de plataforma

### S3

- XRD: `xrd/s3-xrd.yaml`
- Composition: `compositions/s3.yaml`
- Claim consumido por apps: `kind: S3`

A composition cria:
- `Bucket`
- `BucketPublicAccessBlock`
- `BucketServerSideEncryptionConfiguration`
- `BucketVersioning`

### IRSA

- XRD: `xrd/irsa-xrd.yaml`
- Composition: `compositions/irsa.yaml`
- Claim consumido por apps: `kind: IRSA`

A composition cria:
- `Policy`
- `Role`
- `RolePolicyAttachment`

`IRSA` usa `mode: Pipeline` e lê OIDC do `EnvironmentConfig` `cluster-aws-metadata`.

## Como o OIDC chega na Composition

1. Terraform bootstrap cria `EnvironmentConfig` `cluster-aws-metadata`.
2. `compositions/irsa.yaml` referencia esse EnvironmentConfig.
3. A function `patch-and-transform` injeta `oidcProviderArn` e `oidcIssuerHostpath` no `assumeRolePolicyDocument`.
4. O claim IRSA não precisa informar OIDC.

## Instâncias (consumo)

As instâncias não ficam aqui. Elas ficam em:

- `gitops/storage-s3`

Esse app cria no mesmo release:
- claim `S3`
- claim `IRSA`

## Troubleshooting rápido

- Providers não ficam saudáveis:
  - ver `provider.pkg.crossplane.io`
  - checar role/annotation IRSA no service account do provider.

- Claim IRSA não reconcilia:
  - confirmar se `EnvironmentConfig/cluster-aws-metadata` existe.
  - confirmar se a function `function-patch-and-transform` está instalada.

- Claims não aplicam no Argo:
  - validar se XRD e Composition já estão `Healthy` antes dos apps de instância.

## Comandos úteis

```bash
kubectl get provider.pkg.crossplane.io
kubectl get providerconfig.aws.upbound.io
kubectl get xrd
kubectl get composition
kubectl get environmentconfig
kubectl get s3.platform.lab,irsa.platform.lab -A
```
