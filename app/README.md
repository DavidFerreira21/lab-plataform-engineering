# 🚀 Lab de Platform Engineering: Monorepo API & Web

Este repositório contém um laboratório completo focado em **Platform Engineering** e **DevSecOps**. O objetivo é demonstrar, na prática, o ciclo de vida de uma aplicação desde o desenvolvimento até a publicação segura em containers, usando padrões modernos de automação e segurança.

## 🎯 Objetivos do Lab
- Demonstrar um **monorepo** com dois serviços (API + Web) e pipelines independentes.
- Mostrar práticas de **Shift-Left Security** com SAST e SCA dentro do CI.
- Empacotar apps com **Cloud Native Buildpacks** (sem Dockerfile manual).
- Publicar imagens versionadas no Docker Hub, com rastreabilidade via commit.

## 🧱 Camadas da Plataforma (Roadmap)
A ideia deste lab é abordar **todas as camadas de uma plataforma**. Começamos pela camada de **CI** (pipelines e segurança). As próximas camadas serão adicionadas progressivamente.

**Camada atual**
- **CI/DevSecOps**: SAST, SCA, build, scan e push de imagens.

**Próximas camadas (planejado)**
- **CD/Entrega**: deploy automatizado e estratégias de rollout.
- **Infra/IaC**: provisionamento e ambientes reprodutíveis.
- **Runtime/Segurança**: hardening, políticas e controles em execução.
- **Observabilidade**: logs, métricas, traces e alertas.
- **Governança**: padrões, compliance e qualidade.

## Sumário
- [Stack Tecnológica](#-stack-tecnológica)
- [Arquitetura e Fluxo](#-arquitetura-e-fluxo)
- [Estrutura do Monorepo](#-estrutura-do-monorepo)
- [Serviços](#-serviços)
- [Configuração](#-configuração)
- [Como Rodar Localmente](#-como-rodar-localmente)
- [Pipelines DevSecOps](#-pipelines-devsecops)
- [Segurança e Conceitos](#-segurança-e-conceitos)

---

## 🛠️ Stack Tecnológica

| Categoria | Ferramenta | Descrição |
| :--- | :--- | :--- |
| **Linguagem** | Python 3.11 | Base para API (FastAPI) e Front-end (Flask). |
| **API** | FastAPI + Uvicorn | API REST de cadastro de carros. |
| **Web** | Flask + Jinja2 | UI simples que consome a API. |
| **Banco** | SQLite / MongoDB | SQLite local por padrão; Mongo em produção. |
| **Build** | Cloud Native Buildpacks | Gera imagem OCI sem Dockerfile manual. |
| **SAST** | Bandit | Scanner estático para código Python. |
| **SCA & Image Scan** | Trivy | Analisa CVEs em libs e camadas da imagem. |
| **CI/CD** | GitHub Actions | Orquestra as pipelines de API e Web. |
| **Registry** | Docker Hub | Armazenamento e versionamento de imagens. |

---

## 🧭 Arquitetura e Fluxo

```
[Browser] -> [Web Flask] -> [API FastAPI] -> [SQLite/Mongo]
```

Fluxo principal:
1. Usuário acessa a UI Flask.
2. A UI chama a API via `API_URL`.
3. A API persiste dados em SQLite (local) ou MongoDB (produção).

---

## 🏗️ Estrutura do Monorepo

```text
.
├── .github/workflows/
│   ├── api-pipeline.yml   # Pipeline DevSecOps da API
│   └── web-pipeline.yml   # Pipeline DevSecOps da Web
├── app/
│   ├── api/               # Backend FastAPI
│   │   ├── main.py
│   │   ├── database.py
│   │   ├── requirements.txt
│   │   └── Procfile
│   └── web/               # Frontend Flask
│       ├── app.py
│       ├── templates/
│       │   └── index.html
│       ├── requirements.txt
│       └── Procfile
└── README.md
```

---

## 🧩 Serviços

### API (FastAPI)
- **Endpoints**:
  - `GET /carros` → lista carros
  - `POST /carros` → cria carro
  - `DELETE /carros/{id}` → remove carro
- **Modelo**: `marca`, `modelo`, `ano`
- **Persistência**:
  - SQLite por padrão (arquivo `carros.db` local)
  - MongoDB quando `USE_MONGO=true`

### Web (Flask)
- Formulário simples para cadastro e listagem.
- Consome a API com `requests`.
- `API_URL` define onde a API está exposta.

---

## ⚙️ Configuração

### Variáveis de ambiente

| Variável | Serviço | Padrão | Função |
| :--- | :--- | :--- | :--- |
| `USE_MONGO` | API | `false` | Ativa MongoDB como persistência. |
| `API_URL` | Web | `http://127.0.0.1:8000/carros` | Endpoint da API consumido pelo front. |
| `FLASK_DEBUG` | Web | `false` | Modo debug do Flask. |

Observação: o `MONGO_URL` está definido no `database.py` e pode ser ajustado conforme o ambiente.

---

## ▶️ Como Rodar Localmente

### 1) API
```bash
cd app/api
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 2) Web
```bash
cd app/web
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py
```

Acesse: `http://127.0.0.1:5000`

---

## 🔁 Pipelines DevSecOps

Cada serviço tem sua própria pipeline, acionada por mudanças no respectivo diretório.

### Etapas principais (API e Web)
1. **Checkout** do código.
2. **SAST (Bandit)**: análise estática de segurança no código Python.
3. **Buildpacks**: empacota a aplicação em imagem OCI.
4. **Trivy (SCA + Image Scan)**: varredura de vulnerabilidades em libs e imagem.
5. **Push** no Docker Hub com tags:
   - **Short SHA** para rastreabilidade (ex: `lab-api-carro:7a2f1b3`)
   - **latest** para conveniência de uso local

Triggers:
- `app/api/**` → pipeline da API
- `app/web/**` → pipeline da Web

---

## 🔐 Segurança e Conceitos

### Shift-Left Security
Prática de trazer verificações de segurança para o início do ciclo (CI), evitando que falhas cheguem à produção.

### SAST (Bandit)
Bandit é uma ferramenta de **SAST** para Python que inspeciona o código-fonte em busca de padrões inseguros (ex.: uso perigoso de `subprocess`, permissões amplas, binds inseguros). Ele não executa a aplicação; faz análise estática para apontar riscos cedo no ciclo de desenvolvimento.

Site oficial: [Bandit](https://bandit.readthedocs.io/)

### SCA & Image Scan (Trivy)
Trivy é um scanner de segurança para **SCA** e **imagens de container**. Ele identifica CVEs em dependências (bibliotecas) e em camadas do sistema operacional da imagem, ajudando a evitar deploy de artefatos com vulnerabilidades conhecidas.

Site oficial: [Trivy](https://trivy.dev/)

### Justificativas de exceções
- **Bandit B104**: bind em `0.0.0.0` é necessário para containers/Kubernetes.
- **Trivy**: falha apenas em vulnerabilidades **CRITICAL** com correção disponível (`fixed`), evitando bloqueios em falhas do SO base sem patch.

---

## 🚀 Configuração do Repositório

### Secrets necessários
Para que as pipelines funcionem, adicione em `Settings > Secrets and variables > Actions`:

```text
DOCKERHUB_USERNAME=seu_usuario_dockerhub
DOCKERHUB_TOKEN=seu_token_de_acesso
```
