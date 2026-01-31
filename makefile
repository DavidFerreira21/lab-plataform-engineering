# ==========================================
# VARIÁVEIS
# ==========================================
CLUSTER_NAME=dev
NAMESPACE_ARGO=argocd
BIN_DIR=/usr/local/bin

.PHONY: all setup cluster install-nginx install-argo bootstrap-argo status down help

# ==========================================
# COMANDO PRINCIPAL
# ==========================================
all: setup cluster install-nginx install-argo bootstrap-argo config-bash

help: ## Ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# ==========================================
# INSTALAÇÃO DE DEPENDÊNCIAS
# ==========================================
setup: ## Verifica e instala todas as dependências
	@echo "🔍 Verificando ferramentas..."
	
	@if ! command -v docker &> /dev/null; then \
		echo "🐳 Instalando Docker..."; \
		sudo apt-get update && sudo apt-get install -y docker.io; \
		sudo usermod -aG docker ${USER}; \
	fi

	@if ! command -v kubectl &> /dev/null; then \
		echo "☸️ Instalando Kubectl..."; \
		curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"; \
		chmod +x ./kubectl && sudo mv ./kubectl $(BIN_DIR)/kubectl; \
	fi

	@if ! command -v kind &> /dev/null; then \
		echo "🏗️ Instalando Kind..."; \
		curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64; \
		chmod +x ./kind && sudo mv ./kind $(BIN_DIR)/kind; \
	fi

	@if ! command -v helm &> /dev/null; then \
		echo "⛵ Instalando Helm..."; \
		curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; \
	fi
	@echo "✅ Dependências OK"

# ==========================================
# PROVISIONAMENTO DO CLUSTER
# ==========================================
cluster: ## Cria o cluster Kind
	@echo "🏗️ Criando cluster Kind..."
	@kind create cluster --name $(CLUSTER_NAME) --config kind-config.yaml || echo "⚠️ Cluster já existe."

install-nginx: ## Ingress Nginx para Kind
	@echo "🌐 Instalando Ingress Nginx..."
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	@kubectl -n ingress-nginx patch deploy ingress-nginx-controller --type='json' -p='[{"op":"add","path":"/spec/template/spec/nodeSelector","value":{"ingress-ready":"true","kubernetes.io/os":"linux"}}]'
	@kubectl -n ingress-nginx patch deploy ingress-nginx-controller --type='json' -p='[{"op":"add","path":"/spec/template/spec/containers/0/ports/0/hostPort","value":80},{"op":"add","path":"/spec/template/spec/containers/0/ports/1/hostPort","value":443}]'
	@kubectl wait --namespace ingress-nginx --for=condition=Ready pod --selector=app.kubernetes.io/component=controller --timeout=180s

# ==========================================
# GITOPS (ARGO CD)
# ==========================================
install-argo: ## Instalação do ArgoCD
	@echo "🐙 Instalando ArgoCD..."
	@kubectl create namespace $(NAMESPACE_ARGO) || true
	@kubectl apply -n $(NAMESPACE_ARGO) -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "⏳ Aguardando ArgoCD..."
	@kubectl wait --namespace $(NAMESPACE_ARGO) --for=condition=Ready pod --selector=app.kubernetes.io/name=argocd-server --timeout=180s

bootstrap-argo: ## Conecta o Argo ao Monorepo
	@echo "🏗️ Aplicando configurações de GitOps..."
	@kubectl apply -f infra/argo/application.yaml
	@kubectl apply -f infra/argo/ingress.yaml || echo "⚠️ Ingress do Argo não aplicado."
	@echo "🔑 Senha Admin ArgoCD:"
	@kubectl -n $(NAMESPACE_ARGO) get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# ==========================================
# TERMINAL E CLEANUP
# ==========================================
config-bash: ## Melhora a experiência no terminal
	@grep -q "alias k=kubectl" ~/.bashrc || (echo "alias k=kubectl" >> ~/.bashrc && echo "complete -o default -F __start_kubectl k" >> ~/.bashrc)
	@echo "💡 Use 'source ~/.bashrc' para ativar o 'k'."

down: ## Destrói tudo
	@kind delete cluster --name $(CLUSTER_NAME)

status: ## Status resumido
	@kubectl cluster-info
	@kubectl get pods -A