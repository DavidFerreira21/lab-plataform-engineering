from fastapi import FastAPI, Request
from database import USE_MONGO, SessionLocal, CarroSQL, collection, CarroSchema
from bson import ObjectId
import logging
import sys
import json
import time

app = FastAPI()

logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger("api")

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
            collection.insert_one(carro_dict)
        else:
            db = SessionLocal()
            novo = CarroSQL(**carro_dict)
            db.add(novo)
            db.commit()

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

@app.get("/carros")
def get_carros():
    return CarroRepo.listar()

@app.post("/carros")
def post_carro(carro: CarroSchema):
    CarroRepo.salvar(carro.dict())
    return {"status": "ok"}

@app.delete("/carros/{carro_id}")
def delete_carro(carro_id: str): # Recebe string pois o ID do Mongo é hash
    CarroRepo.deletar(carro_id)
    return {"status": "removido"}
