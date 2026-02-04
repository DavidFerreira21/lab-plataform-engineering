import os

from pydantic import BaseModel
from pymongo import MongoClient
from sqlalchemy import Column, Integer, String, create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

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
    documento_key = Column(String, nullable=True)


# --- CONFIGURAÇÃO MONGO ---
MONGO_URL = "mongodb://localhost:27017"
mongo_client = MongoClient(MONGO_URL)
mongo_db = mongo_client["garagem_db"]
collection = mongo_db["carros"]


def ensure_sqlite_schema():
    # Em ambientes de lab, garante a coluna sem migradores externos
    with engine.connect() as conn:
        cols = conn.execute(text("PRAGMA table_info(carros)")).fetchall()
        col_names = {row[1] for row in cols}
        if "documento_key" not in col_names:
            conn.execute(text("ALTER TABLE carros ADD COLUMN documento_key VARCHAR"))


# Inicialização
if not USE_MONGO:
    Base.metadata.create_all(bind=engine)
    ensure_sqlite_schema()


class CarroSchema(BaseModel):
    marca: str
    modelo: str
    ano: int
    documento_key: str | None = None

    class Config:
        from_attributes = True  # Útil para converter de SQL para Pydantic
