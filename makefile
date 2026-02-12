# ==========================================
# VARIÁVEIS
# ==========================================
CLUSTER_NAME=dev
NAMESPACE_ARGO=argocd
BIN_DIR=/usr/local/bin
AWS_REGION?=us-east-1
TF_STATE_BUCKET?=tfstate-terraform-lab-plataform-engineering
TF_BOOTSTRAP_DIR?=plataforma/bootstrap
KARPENTER_NAMESPACE?=karpenter
KARPENTER_VERSION?=1.8.6
KARPENTER_CONTROLLER_ROLE_NAME?=
KARPENTER_CONTROLLER_ROLE_ARN?=
PLATFORM?=kind
EKS_CLUSTER_NAME?=eks-dev
	
.PHONY: all-kind all-eks setup cluster-kind cluster-eks install-nginx-kind install-nginx-eks install-argo bootstrap-argo down down-eks help aws-configure tf-backend-bootstrap tf-eks-init tf-eks-apply eks-configure-context show-hosts

# ==========================================
# COMANDO PRINCIPAL
# ==========================================
all-kind:
	@$(MAKE) setup
	@$(MAKE) cluster-kind
	@$(MAKE) install-nginx-kind
	@$(MAKE) install-argo
	@$(MAKE) bootstrap-argo
	@$(MAKE) config-bash
	@$(MAKE) show-hosts

# ==========================================
# EKS (Terraform + AWS CLI)
# ==========================================
all-eks:
	@$(MAKE) tf-backend-bootstrap
	@$(MAKE) cluster-eks
	@$(MAKE) install-nginx-eks
	@$(MAKE) install-argo PLATFORM=eks
	@$(MAKE) bootstrap-argo PLATFORM=eks
	@$(MAKE) show-hosts PLATFORM=eks

cluster-eks: tf-eks-init tf-eks-apply eks-configure-context ## Cria/atualiza cluster EKS via Terraform e configura kubecontext

tf-eks-init: ## Executa terraform init em plataforma/bootstrap
	@if ! command -v terraform >/dev/null 2>&1; then echo "❌ Terraform não encontrado"; exit 1; fi
	@echo "🔧 Terraform init em $(TF_BOOTSTRAP_DIR)..."
	@cd $(TF_BOOTSTRAP_DIR) && terraform init -reconfigure

tf-eks-apply: ## Executa terraform apply em plataforma/bootstrap
	@if ! command -v terraform >/dev/null 2>&1; then echo "❌ Terraform não encontrado"; exit 1; fi
	@echo "🚀 Terraform apply em $(TF_BOOTSTRAP_DIR)..."
	@cd $(TF_BOOTSTRAP_DIR) && terraform apply -auto-approve

eks-configure-context: ## Atualiza kubeconfig para o cluster EKS criado pelo Terraform
	@if ! command -v aws >/dev/null 2>&1; then echo "❌ AWS CLI não encontrado"; exit 1; fi
	@echo "🔐 Configurando contexto do kubectl para EKS..."
	@CLUSTER_NAME=$$(cd $(TF_BOOTSTRAP_DIR) && terraform output -raw cluster_name 2>/dev/null); \
	if [ -z "$$CLUSTER_NAME" ]; then CLUSTER_NAME=$(EKS_CLUSTER_NAME); fi; \
	aws eks update-kubeconfig --region $(AWS_REGION) --name $$CLUSTER_NAME

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

tf-backend-bootstrap: ## Cria bucket S3 do state (se nao existir) e aplica configuracoes
	@if ! command -v aws >/dev/null 2>&1; then echo "❌ AWS CLI não encontrado"; exit 1; fi
	@AWS_REGION=$(AWS_REGION); \
	if [ -z "$$AWS_REGION" ]; then echo "❌ AWS_REGION vazio"; exit 1; fi; \
	BUCKET=$(TF_STATE_BUCKET); \
	if aws s3api head-bucket --bucket $$BUCKET >/dev/null 2>&1; then \
		echo "ℹ️ Bucket já existe: $$BUCKET"; \
	else \
		echo "🪣 Criando bucket: $$BUCKET (região $$AWS_REGION)"; \
		if [ "$$AWS_REGION" = "us-east-1" ]; then \
			aws s3api create-bucket --bucket $$BUCKET --region $$AWS_REGION; \
		else \
			aws s3api create-bucket --bucket $$BUCKET --region $$AWS_REGION --create-bucket-configuration LocationConstraint=$$AWS_REGION; \
		fi; \
	fi; \
	echo "🔒 Aplicando configurações no bucket $$BUCKET..."; \
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

show-hosts: ## Exibe comando para configurar hosts locais dos ingress
	@if [ "$(PLATFORM)" = "eks" ]; then \
		LB_IP=$$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].ip}" 2>/dev/null); \
		LB_HOST=$$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" 2>/dev/null); \
		if [ -z "$$LB_IP" ] && [ -n "$$LB_HOST" ]; then \
			LB_IP=$$(getent ahostsv4 $$LB_HOST 2>/dev/null | awk 'NR==1{print $$1}'); \
		fi; \
		echo "🌐 Ingress EKS detectado."; \
		if [ -n "$$LB_IP" ]; then \
			echo "Adicione no /etc/hosts:"; \
			echo "$$LB_IP argocd.local api.local web.local"; \
			echo "Comando:"; \
			echo "echo \"$$LB_IP argocd.local api.local web.local\" | sudo tee -a /etc/hosts"; \
		else \
			echo "⚠️ Não foi possível resolver IP do ingress ainda."; \
			echo "Hostname atual do LB: $$LB_HOST"; \
			echo "Aguarde o LoadBalancer ficar pronto e rode: make show-hosts PLATFORM=eks"; \
		fi; \
	else \
		echo "🌐 Para acessar os ingress locais, adicione no /etc/hosts:"; \
		echo "127.0.0.1 argocd.local api.local web.local"; \
		echo "Comando:"; \
		echo "echo \"127.0.0.1 argocd.local api.local web.local\" | sudo tee -a /etc/hosts"; \
	fi

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

helm-build: ## Atualiza dependências Helm (api + web)
	@echo "⛵ Atualizando dependências Helm..."
	@helm dependency build gitops/app
	@helm dependency build gitops/web
	@echo "✅ Dependências atualizadas."
