from fastapi import FastAPI
from database import USE_MONGO, SessionLocal, CarroSQL, collection, CarroSchema
from bson import ObjectId

app = FastAPI()

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
