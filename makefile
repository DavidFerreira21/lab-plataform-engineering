# ==========================================
# VARIÁVEIS
# ==========================================
CLUSTER_NAME=dev
NAMESPACE_ARGO=argocd
BIN_DIR=/usr/local/bin
AWS_REGION?=us-east-1
TF_STATE_BUCKET?=tfstate-terraform-lab-plataform-engineering
EKS_BOOTSTRAP?=./eks-bootstrap.sh
KARPENTER_NAMESPACE?=karpenter
KARPENTER_VERSION?=1.8.6
KARPENTER_CONTROLLER_ROLE_NAME?=
KARPENTER_CONTROLLER_ROLE_ARN?=
PLATFORM?=kind

.PHONY: all-kind all-eks setup cluster-kind install-nginx-kind install-nginx-eks install-argo bootstrap-argo down down-eks help aws-configure tf-backend-bootstrap eks-bootstrap

# ==========================================
# COMANDO PRINCIPAL
# ==========================================
all-kind: setup cluster-kind install-nginx-kind install-argo bootstrap-argo config-bash

# ==========================================
# EKS (AWS CLI)
# ==========================================
all-eks:
	@$(MAKE) eks-bootstrap
	@$(MAKE) install-nginx-eks
	@$(MAKE) install-argo
	@$(MAKE) bootstrap-argo PLATFORM=eks

eks-bootstrap: ## Cria cluster EKS + managed node group via AWS CLI
	@$(EKS_BOOTSTRAP)

help: ## Ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# ==========================================
# INSTALAÇÃO DE DEPENDÊNCIAS
# ==========================================
setup: ## Verifica e instala Docker, Kubectl, Kind e Helm
	@echo "🔍 Verificando ferramentas..."
	@# Docker
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "🐳 Docker não encontrado. Instalando..."; \
		sudo apt-get update && sudo apt-get install -y docker.io; \
		sudo usermod -aG docker ${USER}; \
	else \
		echo "✅ Docker já está instalado"; \
	fi
	@# Kubectl
	@if ! command -v kubectl >/dev/null 2>&1; then \
		echo "☸️ Kubectl não encontrado. Instalando..."; \
		curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"; \
		chmod +x ./kubectl && sudo mv ./kubectl $(BIN_DIR)/kubectl; \
	else \
		echo "✅ Kubectl já está instalado"; \
	fi
	@# Kind
	@if ! command -v kind >/dev/null 2>&1; then \
		echo "🏗️ Kind não encontrado. Instalando..."; \
		curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64; \
		chmod +x ./kind && sudo mv ./kind $(BIN_DIR)/kind; \
	else \
		echo "✅ Kind já está instalado"; \
	fi
	@# Helm
	@if ! command -v helm >/dev/null 2>&1; then \
		echo "⛵ Helm não encontrado. Instalando..."; \
		curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; \
	else \
		echo "✅ Helm já está instalado"; \
	fi

# ==========================================
# AWS (BOOTSTRAP DO BACKEND)
# ==========================================
aws-configure: ## Configura credenciais AWS (aws configure)
	@aws configure

tf-backend-bootstrap: ## Cria bucket S3 e atualiza backend.tf automaticamente
	@if ! command -v aws >/dev/null 2>&1; then echo "❌ AWS CLI não encontrado"; exit 1; fi
	@AWS_REGION=$(AWS_REGION); \
	if [ -z "$$AWS_REGION" ]; then echo "❌ AWS_REGION vazio"; exit 1; fi; \
	BUCKET=$(TF_STATE_BUCKET); \
	echo "🪣 Criando bucket: $$BUCKET (região $$AWS_REGION)"; \
	if [ "$$AWS_REGION" = "us-east-1" ]; then \
		aws s3api create-bucket --bucket $$BUCKET --region $$AWS_REGION; \
	else \
		aws s3api create-bucket --bucket $$BUCKET --region $$AWS_REGION --create-bucket-configuration LocationConstraint=$$AWS_REGION; \
	fi; \
	aws s3api put-bucket-versioning --bucket $$BUCKET --versioning-configuration Status=Enabled; \
	aws s3api put-public-access-block --bucket $$BUCKET --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true; \
	aws s3api put-bucket-encryption --bucket $$BUCKET --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'; \
	echo "✅ Bucket pronto: $$BUCKET"

# ==========================================
# PROVISIONAMENTO DO CLUSTER
# ==========================================
cluster-kind: ## Cria o cluster Kind se não existir
	@echo "🏗️ Verificando cluster Kind..."
	@if ! kind get clusters | grep -q "^$(CLUSTER_NAME)$$"; then \
		if [ ! -f kind-config.yaml ]; then echo "❌ Erro: kind-config.yaml não encontrado!"; exit 1; fi; \
		kind create cluster --name $(CLUSTER_NAME) --config kind-config.yaml; \
	else \
		echo "⚠️ Cluster '$(CLUSTER_NAME)' já existe."; \
	fi


install-nginx-kind: ## Instala e configura o Nginx Ingress para Kind
	@echo "🌐 Instalando Nginx Ingress Controller..."
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	@echo "🛠️ Aplicando patches para rodar no Kind..."
	@kubectl -n ingress-nginx patch deploy ingress-nginx-controller --type='json' -p='[{"op":"add","path":"/spec/template/spec/nodeSelector","value":{"ingress-ready":"true","kubernetes.io/os":"linux"}}]'
	@kubectl -n ingress-nginx patch deploy ingress-nginx-controller --type='json' -p='[{"op":"add","path":"/spec/template/spec/containers/0/ports/0/hostPort","value":80},{"op":"add","path":"/spec/template/spec/containers/0/ports/1/hostPort","value":443}]'
	@echo "⏳ Aguardando Nginx ficar pronto (isso pode levar uns minutos)..."
	@kubectl wait --namespace ingress-nginx --for=condition=Ready pod --selector=app.kubernetes.io/component=controller --timeout=180s

install-nginx-eks: ## Instala Nginx Ingress no EKS (provider AWS)
	@echo "🌐 Instalando Nginx Ingress Controller no EKS..."
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml
	@echo "⏳ Aguardando Nginx ficar pronto (isso pode levar uns minutos)..."
	@kubectl wait --namespace ingress-nginx --for=condition=Ready pod --selector=app.kubernetes.io/component=controller --timeout=180s

# ==========================================
# GITOPS (ARGO CD)
# ==========================================
install-argo: ## Instalação do ArgoCD
	@echo "🐙 Instalando ArgoCD..."
	@kubectl create namespace $(NAMESPACE_ARGO) || true
	@if [ "$(PLATFORM)" = "eks" ]; then \
		kubectl apply --server-side -n $(NAMESPACE_ARGO) -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml; \
	else \
		kubectl apply --server-side -n $(NAMESPACE_ARGO) -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml; \
	fi
	@echo "⏳ Aguardando ArgoCD..."
	@kubectl -n $(NAMESPACE_ARGO) rollout status deploy/argocd-server --timeout=300s || true
	@kubectl -n $(NAMESPACE_ARGO) rollout status deploy/argocd-repo-server --timeout=300s || true
	@kubectl -n $(NAMESPACE_ARGO) rollout status sts/argocd-application-controller --timeout=300s || true

bootstrap-argo: ## Conecta o Argo ao Monorepo
	@echo "🏗️ Aplicando configurações de GitOps..."
	@kubectl apply -f plataforma/argo/application.yaml
	@if [ "$(PLATFORM)" = "eks" ]; then \
		kubectl apply -f plataforma/argo/ingress-eks.yaml; \
	else \
		kubectl apply -f plataforma/argo/ingress.yaml; \
	fi
	@echo "🔑 Senha Admin ArgoCD:"
	@kubectl -n $(NAMESPACE_ARGO) get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
	@echo "🌐 NLB/ELB do Ingress:"
	@kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"; echo

# ==========================================
# TERMINAL E CLEANUP
# ==========================================
config-bash: ## Melhora a experiência no terminal
	@grep -q "alias k=kubectl" ~/.bashrc || (echo "alias k=kubectl" >> ~/.bashrc && echo "complete -o default -F __start_kubectl k" >> ~/.bashrc)
	@echo "💡 Use 'source ~/.bashrc' para ativar o 'k'."

down: ## Destrói tudo
	@kind delete cluster --name $(CLUSTER_NAME)

down-eks: ## Remove o cluster EKS e o node group (AWS CLI)
	@if [ -z "$(AWS_REGION)" ]; then echo "❌ AWS_REGION vazio"; exit 1; fi
	@EKS_NAME=$(EKS_CLUSTER_NAME); \
	if [ -z "$$EKS_NAME" ]; then EKS_NAME=$(CLUSTER_NAME); fi; \
	echo "🧹 Removendo node group tools..."; \
	aws eks delete-nodegroup --region $(AWS_REGION) --cluster-name $$EKS_NAME --nodegroup-name tools >/dev/null 2>&1 || true; \
	echo "⏳ Aguardando node group remover..."; \
	aws eks wait nodegroup-deleted --region $(AWS_REGION) --cluster-name $$EKS_NAME --nodegroup-name tools >/dev/null 2>&1 || true; \
	echo "🧹 Removendo cluster EKS..."; \
	aws eks delete-cluster --region $(AWS_REGION) --name $$EKS_NAME; \
	echo "⏳ Aguardando cluster remover..."; \
	aws eks wait cluster-deleted --region $(AWS_REGION) --name $$EKS_NAME

status: ## Status resumido
	@kubectl cluster-info
	@kubectl get pods -A
helm-build: ## Atualiza dependências Helm (api + web)
	@echo "⛵ Atualizando dependências Helm..."
	@helm dependency build gitops/app
	@helm dependency build gitops/web
	@echo "✅ Dependências atualizadas."
EKS_CLUSTER_NAME?=eks-dev
