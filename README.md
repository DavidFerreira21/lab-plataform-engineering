# Lab de Platform Engineering (Monorepo API + Web)

Este repositorio e um laboratorio pratico de Platform Engineering e DevSecOps.
O objetivo e exercitar um fluxo completo de produto de plataforma: bootstrap de cluster, produtos via Crossplane, deploy GitOps e aplicacoes consumidoras.

## Objetivos do lab
- Padronizar deploy de apps via Helm + ArgoCD.
- Oferecer recursos de infraestrutura como produto (S3, IRSA, RDS) com Crossplane.
- Testar portabilidade entre contas AWS sem alterar codigo da aplicacao.
- Validar governanca com Kyverno em modo Audit.

## Arquitetura em camadas
- `app/`: codigo das aplicacoes (`api` FastAPI e `web` Flask).
- `gitops/`: charts e values de deploy das apps e do contrato unico de infra.
- `plataforma/bootstrap/`: Terraform para EKS e add-ons do cluster.
- `plataforma/crossplane/`: XRDs, Compositions e providers.
- `plataforma/argo/`: Applications e AppProject do ArgoCD.
- `plataforma/kyverno/`: politicas de validacao (warning/audit).

## Estrutura do repositorio

```text
.
├── app/
│   ├── api/
│   └── web/
├── gitops/
│   ├── app/
│   ├── web/
│   └── garagem-infra/
├── plataforma/
│   ├── argo/
│   ├── bootstrap/
│   ├── cluster-metadata/
│   ├── crossplane/
│   ├── helm-charts/
│   ├── kyverno/
│   └── minio/
├── makefile
└── kind-config.yaml
```

## Ambientes suportados
- `kind` (local): apps + MinIO + ArgoCD.
- `eks` (AWS): bootstrap via Terraform, Crossplane (contrato unico `XPythonAppInfra`), apps via ArgoCD.

## ArgoCD por ambiente
### Kind
- `platform-apps`: API + Web + MinIO.

### EKS
- `platform-core`: Crossplane base/xrd/compositions + cluster-metadata + Kyverno.
- `garagem-infra`: contrato de infraestrutura da app (`XPythonAppInfra`).
- `garagem-app`: workloads (`gitops/app` e `gitops/web`).

Separar `core`, `infra` e `app` facilita troubleshooting e reduz acoplamento de sync.

## Fluxo rapido
### Local com Kind
```bash
make all-kind
```

### AWS com EKS
```bash
make all-eks
```

## Targets principais do Make
- `make all-kind`: setup + cluster kind + ingress + Argo + bootstrap GitOps.
- `make all-eks`: backend terraform + apply EKS/addons + bootstrap GitOps EKS.
- `make cluster-eks`: terraform init/apply e `aws eks update-kubeconfig`.
- `make bootstrap-argo PLATFORM=kind|eks`: aplica Applications do Argo.
- `make helm-build`: atualiza dependencias Helm dos charts versionados no repo.
- `make down` / `make down-eks`: teardown local / AWS.

## Sequencia EKS (resumo)
1. Terraform cria/atualiza o cluster (`module.eks`).
2. Terraform instala add-ons (`module.addons`): Crossplane, External Secrets, ArgoCD, ingress-nginx, Kyverno (por flags).
3. Argo aplica `platform-core`, `garagem-infra`, `garagem-app`.
4. O contrato `XPythonAppInfra` provisiona recursos e secrets de conexao.
5. API consome secrets (S3 e RDS) sem resolver nomes dinamicamente em runtime.

## Boas praticas do lab
- Mudou chart base? rode `make helm-build` e commite `Chart.lock` e `charts/*.tgz`.
- Evite hardcode de conta/regiao em app; use secret de conexao do Crossplane.
- Em EKS, prefira IRSA para acesso AWS (sem access key fixa no pod).

## Documentacao detalhada
- Apps: `app/README.md`
- Plataforma: `plataforma/README.md`
- Bootstrap Terraform: `plataforma/bootstrap/README.md`
- Crossplane: `plataforma/crossplane/README.md`
