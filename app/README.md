# Apps (API + Web)

Esta pasta contem a camada de aplicacao do lab: **API (FastAPI)** e **Web (Flask)**.

## Servicos

### API (FastAPI)
Endpoints principais:
- `GET /carros`
- `POST /carros`
- `DELETE /carros/{id}`
- `POST /carros/{id}/documento`
- `GET /healthz`

Persistencia:
- PostgreSQL (RDS) em EKS via variaveis `DB_*` ou `DATABASE_URL`
- SQLite como fallback local

Upload S3:
- A API usa **diretamente** o valor de `S3_BUCKET`
- Nao existe mais resolucao dinamica de nome de bucket dentro do codigo
- Em EKS, `S3_BUCKET` vem do secret `api-storage-conn` (`bucketName`)

### Web (Flask)
Rotas principais:
- `/`
- `/cadastrar`
- `/excluir/<id>`
- `/healthz`

A Web consome a API pela variavel `API_URL`.

## Variaveis de ambiente

### API
- `DATABASE_URL` (opcional)
- `DB_HOST`
- `DB_PORT`
- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`
- `S3_ENDPOINT`
- `S3_BUCKET`
- `S3_ACCESS_KEY`
- `S3_SECRET_KEY`
- `S3_REGION`
- `S3_USE_SSL`

### Web
- `API_URL`
- `FLASK_DEBUG`

## Helm values

### API
- `gitops/app/values-kind.yaml`
  - fluxo local com MinIO
- `gitops/app/values-eks.yaml`
  - `S3_BUCKET` via `secretKeyRef` em `api-storage-conn.bucketName`
  - `DB_*` via secrets `api-garagem-db-conn` e `api-garagem-db-auth`
  - service account com annotation IRSA

### Web
- `gitops/web/values.yaml`

## Rodar localmente

### API
```bash
cd app/api
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Web
```bash
cd app/web
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py
```

## Testes

### API
```bash
cd app/api
pytest
```

### Web
```bash
cd app/web
pytest
```

## Observacoes
- Upload grande pode exigir ajuste de ingress (`proxy-body-size`).
- Em EKS, se houver erro de upload S3, validar primeiro: role IRSA, policy e valor do secret `api-storage-conn`.
