# Apps (API + Web)

Camada de aplicacao do lab, composta por API e Web.

## Servicos
### API (`app/api`)
Stack: FastAPI + SQLAlchemy + boto3.

Endpoints:
- `GET /carros`
- `POST /carros`
- `DELETE /carros/{id}`
- `POST /carros/{id}/documento`
- `GET /healthz`

Persistencia:
- EKS: PostgreSQL (RDS) via `DB_*` ou `DATABASE_URL`.
- Local: fallback SQLite.

Storage:
- Upload para S3 usando `S3_BUCKET` recebido via ambiente.
- A API nao resolve nome de bucket dinamicamente no codigo.

### Web (`app/web`)
Stack: Flask.

Rotas:
- `/`
- `/cadastrar`
- `/excluir/<id>`
- `/healthz`

A Web chama a API pela variavel `API_URL`.

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

## Configuracao por ambiente
### Kind
- Values API: `gitops/app/values-kind.yaml`
- Storage local: MinIO

### EKS
- Values API: `gitops/app/values-eks.yaml`
- `S3_BUCKET` vem de `api-storage-conn.bucketName`
- `DB_HOST`/`DB_PORT`/`DB_USER` via `api-garagem-db-conn`
- `DB_PASSWORD` via `api-garagem-db-auth`
- ServiceAccount da API recebe annotation IRSA

## Executar localmente
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

## Troubleshooting rapido
- `NoSuchBucket`: validar secret `api-storage-conn` e env `S3_BUCKET` no deploy.
- `InvalidIdentityToken`: validar OIDC provider/trust policy/annotation IRSA.
- Timeout no Postgres: validar SG e regra de ingress do RDS criada pelo Crossplane.
- `relation ... does not exist`: schema/tabela ainda nao criada no banco alvo.
