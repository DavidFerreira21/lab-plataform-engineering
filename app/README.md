# Apps (API + Web)

Esta pasta contém a camada de aplicação do lab: **API (FastAPI)** e **Web (Flask)**. Cada serviço possui:
- código-fonte
- dependências (`requirements.txt`)
- `Procfile`
- Helm chart com values

## Serviços

### API (FastAPI)
- Endpoints:
  - `GET /carros`
  - `POST /carros`
  - `DELETE /carros/{id}`
- Modelo: `marca`, `modelo`, `ano`
- Persistência:
  - **SQLite** por padrão (`carros.db` local)
  - **MongoDB** quando `USE_MONGO=true`

### Web (Flask)
- Formulário para cadastro e listagem de carros
- Consome a API via `API_URL`
- Rotas principais:
  - `/` (lista)
  - `/cadastrar` (POST)
  - `/excluir/<id>`

## Variáveis de ambiente

### API
- `USE_MONGO` (padrão: `false`) ativa MongoDB
- `MONGO_URL` (padrão em `database.py`: `mongodb://localhost:27017`)

### Web
- `API_URL` (padrão: `http://127.0.0.1:8000/carros`)
- `FLASK_DEBUG` (padrão: `false`)

## Helm values (Kubernetes)

### API
Arquivo: `app/api/values.yaml`
- `image.repository` / `image.tag`
- `service.port` (porta do Service)
- `service.targetPort` (porta real do container, API roda em 8000)

### Web
Arquivo: `app/web/values.yaml`
- `image.repository` / `image.tag`
- `service.port` (porta do Service)
- `service.targetPort` (porta real do container, Web roda em 5000)
- `ingress.enabled` / `ingress.host`
- `env.API_URL` apontando para o Service da API no cluster

## Como rodar localmente

### API
```bash
cd app/api
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Web
```bash
cd app/web
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py
```

Acesse: `http://127.0.0.1:5000`

## Observações
- A Web precisa do `API_URL` correto para funcionar dentro do cluster.
- Em Kubernetes, o Service da API é `platform-api-svc` quando o releaseName é `platform-api`.
