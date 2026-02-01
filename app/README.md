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
  - `POST /carros/{id}/documento` (upload para MinIO/S3)
  - `GET /healthz` (readiness/liveness)
- Modelo: `marca`, `modelo`, `ano`
- Campo adicional: `documento_key` (caminho do arquivo no storage)
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
  - `/healthz` (readiness/liveness)

## Variáveis de ambiente

### API
- `USE_MONGO` (padrão: `false`) ativa MongoDB
- `MONGO_URL` (padrão em `database.py`: `mongodb://localhost:27017`)
- `S3_ENDPOINT` (ex.: `http://minio:9000`)
- `S3_BUCKET` (ex.: `carros`)
- `S3_ACCESS_KEY` / `S3_SECRET_KEY`
- `S3_REGION` (ex.: `us-east-1`)
- `S3_USE_SSL` (`true` ou `false`)

### Web
- `API_URL` (padrão: `http://127.0.0.1:8000/carros`)
- `FLASK_DEBUG` (padrão: `false`)

## Helm values (Kubernetes)

### API
Arquivo: `app/api/values.yaml`
- `image.repository` / `image.tag`
- `service.port` (porta do Service)
- `service.targetPort` (porta real do container, API roda em 8000)
- `service.name` (nome fixo do Service)
- `probes.*` (readiness/liveness)
- `env` com variáveis S3/MinIO

### Web
Arquivo: `app/web/values.yaml`
- `image.repository` / `image.tag`
- `service.port` (porta do Service)
- `service.targetPort` (porta real do container, Web roda em 5000)
- `service.name` (nome fixo do Service)
- `ingress.enabled` / `ingress.host`
- `ingress.annotations` (ex.: `proxy-body-size`)
- `env.API_URL` apontando para o Service da API no cluster
- `probes.*` (readiness/liveness)

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
- O nome do Service é configurado via `service.name` (ex.: `api-carro`, `web-carro`).
- Uploads grandes podem exigir ajuste no Ingress (`proxy-body-size`).
- Os probes usam `/healthz` para evitar dependência da API na rota `/`.
