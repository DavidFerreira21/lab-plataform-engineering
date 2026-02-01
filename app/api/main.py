from fastapi import FastAPI, Request, UploadFile, File, HTTPException
from database import USE_MONGO, SessionLocal, CarroSQL, collection, CarroSchema
from bson import ObjectId
import logging
import sys
import json
import time
import os
import boto3

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
    if not S3_ACCESS_KEY or not S3_SECRET_KEY:
        raise RuntimeError("S3 credentials not configured")
    return boto3.client(
        "s3",
        endpoint_url=S3_ENDPOINT,
        aws_access_key_id=S3_ACCESS_KEY,
        aws_secret_access_key=S3_SECRET_KEY,
        region_name=S3_REGION,
        use_ssl=S3_USE_SSL,
    )

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
        if USE_MONGO:
            # Converte o _id do Mongo para string para o JSON aceitar
            lista = list(collection.find())
            for item in lista:
                item["id"] = str(item["_id"])
            return lista
        else:
            db = SessionLocal()
            return db.query(CarroSQL).all()

    @staticmethod
    def salvar(carro_dict):
        if USE_MONGO:
            result = collection.insert_one(carro_dict)
            return str(result.inserted_id)
        else:
            db = SessionLocal()
            novo = CarroSQL(**carro_dict)
            db.add(novo)
            db.commit()
            db.refresh(novo)
            return str(novo.id)

    @staticmethod
    def deletar(carro_id):
        if USE_MONGO:
            collection.delete_one({"_id": ObjectId(carro_id)})
        else:
            db = SessionLocal()
            carro = db.query(CarroSQL).filter(CarroSQL.id == carro_id).first()
            if carro:
                db.delete(carro)
                db.commit()

    @staticmethod
    def atualizar_documento(carro_id, documento_key):
        if USE_MONGO:
            collection.update_one(
                {"_id": ObjectId(carro_id)},
                {"$set": {"documento_key": documento_key}},
            )
        else:
            db = SessionLocal()
            carro = db.query(CarroSQL).filter(CarroSQL.id == int(carro_id)).first()
            if carro:
                carro.documento_key = documento_key
                db.commit()

@app.get("/carros")
def get_carros():
    return CarroRepo.listar()

@app.post("/carros")
def post_carro(carro: CarroSchema):
    carro_id = CarroRepo.salvar(carro.dict())
    return {"status": "ok", "id": carro_id}

@app.delete("/carros/{carro_id}")
def delete_carro(carro_id: str): # Recebe string pois o ID do Mongo é hash
    CarroRepo.deletar(carro_id)
    return {"status": "removido"}

@app.post("/carros/{carro_id}/documento")
async def upload_documento(carro_id: str, documento: UploadFile = File(...)):
    try:
        s3 = get_s3_client()
    except RuntimeError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    key = f"{carro_id}/{documento.filename}"
    try:
        s3.upload_fileobj(documento.file, S3_BUCKET, key)
    except Exception as exc:
        raise HTTPException(status_code=500, detail="upload_failed") from exc

    CarroRepo.atualizar_documento(carro_id, key)
    return {"status": "ok", "bucket": S3_BUCKET, "key": key}

