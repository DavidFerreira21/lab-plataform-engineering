import logging
import sys
import json
import time
import os

import boto3
from fastapi import FastAPI, Request, UploadFile, File, HTTPException

from database import SessionLocal, CarroSQL, CarroSchema

app = FastAPI()

logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger("api")

S3_ENDPOINT = os.getenv("S3_ENDPOINT", "http://minio:9000")
S3_BUCKET = os.getenv("S3_BUCKET", "carros")
S3_ACCESS_KEY = os.getenv("S3_ACCESS_KEY", "")
S3_SECRET_KEY = os.getenv("S3_SECRET_KEY", "")
S3_REGION = os.getenv("S3_REGION", "us-east-1")
S3_USE_SSL = os.getenv("S3_USE_SSL", "false").lower() == "true"


def get_s3_client():
    client_kwargs = {
        "endpoint_url": S3_ENDPOINT,
        "region_name": S3_REGION,
        "use_ssl": S3_USE_SSL,
    }

    if S3_ACCESS_KEY and S3_SECRET_KEY:
        client_kwargs["aws_access_key_id"] = S3_ACCESS_KEY
        client_kwargs["aws_secret_access_key"] = S3_SECRET_KEY
    else:
        log_json(
            logging.INFO,
            "s3_auth_fallback",
            detail="Using boto3 default credential chain (e.g. IRSA)",
        )

    return boto3.client("s3", **client_kwargs)


def log_json(level, message, **fields):
    payload = {"level": level, "message": message, **fields}
    logger.log(level, json.dumps(payload, ensure_ascii=True))


@app.middleware("http")
async def log_requests(request: Request, call_next):
    start = time.perf_counter()
    try:
        response = await call_next(request)
        duration_ms = round((time.perf_counter() - start) * 1000, 2)
        log_json(
            logging.INFO,
            "request",
            method=request.method,
            path=request.url.path,
            status_code=response.status_code,
            duration_ms=duration_ms,
        )
        return response
    except Exception as exc:
        duration_ms = round((time.perf_counter() - start) * 1000, 2)
        log_json(
            logging.ERROR,
            "request_error",
            method=request.method,
            path=request.url.path,
            status_code=500,
            duration_ms=duration_ms,
            error=str(exc),
        )
        raise


class CarroRepo:
    @staticmethod
    def listar():
        db = SessionLocal()
        itens = db.query(CarroSQL).all()
        if itens and isinstance(itens[0], dict):
            return itens
        return [
            {
                "id": carro.id,
                "marca": carro.marca,
                "modelo": carro.modelo,
                "ano": carro.ano,
                "documento_key": carro.documento_key,
            }
            for carro in itens
        ]

    @staticmethod
    def salvar(carro_dict):
        db = SessionLocal()
        novo = CarroSQL(**carro_dict)
        db.add(novo)
        db.commit()
        db.refresh(novo)
        return str(novo.id)

    @staticmethod
    def deletar(carro_id):
        db = SessionLocal()
        carro = db.query(CarroSQL).filter(CarroSQL.id == carro_id).first()
        if carro:
            db.delete(carro)
            db.commit()

    @staticmethod
    def atualizar_documento(carro_id, documento_key):
        db = SessionLocal()
        carro = db.query(CarroSQL).filter(CarroSQL.id == int(carro_id)).first()
        if carro:
            carro.documento_key = documento_key
            db.commit()


@app.get("/carros")
def get_carros():
    return CarroRepo.listar()


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.post("/carros")
def post_carro(carro: CarroSchema):
    carro_id = CarroRepo.salvar(carro.dict())
    return {"status": "ok", "id": carro_id}


@app.delete("/carros/{carro_id}")
def delete_carro(carro_id: str):  # Recebe string pois o ID do Mongo é hash
    CarroRepo.deletar(int(carro_id))
    return {"status": "removido"}


@app.post("/carros/{carro_id}/documento")
async def upload_documento(carro_id: str, documento: UploadFile = File(...)):
    try:
        s3 = get_s3_client()
    except RuntimeError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    key = f"{carro_id}/{documento.filename}"
    bucket_name = S3_BUCKET
    try:
        s3.upload_fileobj(documento.file, bucket_name, key)
    except Exception as exc:
        log_json(
            logging.ERROR,
            "s3_upload_failed",
            error_type=type(exc).__name__,
            error=str(exc),
            bucket=bucket_name,
            key=key,
            endpoint=S3_ENDPOINT,
            region=S3_REGION,
        )
        raise HTTPException(status_code=500, detail="upload_failed") from exc

    CarroRepo.atualizar_documento(carro_id, key)
    return {"status": "ok", "bucket": bucket_name, "key": key}
