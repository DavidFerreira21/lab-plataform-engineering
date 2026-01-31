import os
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from pymongo import MongoClient
from pydantic import BaseModel

# Carregar configuração (pode vir de um arquivo .env)
USE_MONGO = os.getenv("USE_MONGO", "false").lower() == "true"

# --- CONFIGURAÇÃO SQLITE ---
SQLALCHEMY_DATABASE_URL = "sqlite:///./carros.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()

class CarroSQL(Base):
    __tablename__ = "carros"
    id = Column(Integer, primary_key=True, index=True)
    marca = Column(String)
    modelo = Column(String)
    ano = Column(Integer)

# --- CONFIGURAÇÃO MONGO ---
MONGO_URL = "mongodb://localhost:27017"
mongo_client = MongoClient(MONGO_URL)
mongo_db = mongo_client["garagem_db"]
collection = mongo_db["carros"]

# Inicialização
if not USE_MONGO:
    Base.metadata.create_all(bind=engine)

class CarroSchema(BaseModel):
    marca: str
    modelo: str
    ano: int

    class Config:
        from_attributes = True # Útil para converter de SQL para Pydantic
    