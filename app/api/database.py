import os
import sys
from urllib.parse import quote_plus

from pydantic import BaseModel
from sqlalchemy import Column, Integer, String, create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

DATABASE_URL = os.getenv("DATABASE_URL", "").strip()
DB_HOST = os.getenv("DB_HOST", "").strip()
DB_PORT = os.getenv("DB_PORT", "5432").strip() or "5432"
DB_NAME = os.getenv("DB_NAME", "garagem").strip() or "garagem"
DB_USER = os.getenv("DB_USER", "appuser").strip() or "appuser"
DB_PASSWORD = os.getenv("DB_PASSWORD", "").strip()

if not DATABASE_URL and DB_HOST:
    DATABASE_URL = (
        f"postgresql+psycopg2://{quote_plus(DB_USER)}:"
        f"{quote_plus(DB_PASSWORD)}@{DB_HOST}:{DB_PORT}/{quote_plus(DB_NAME)}"
    )

if not DATABASE_URL:
    DATABASE_URL = "sqlite:///./carros.db"

IS_SQLITE = DATABASE_URL.startswith("sqlite")

if IS_SQLITE:
    # Buildpacks minimalistas podem não trazer libsqlite3 do SO.
    # Nesse caso, tenta usar pysqlite3-binary para fornecer o módulo sqlite3.
    try:
        import sqlite3  # noqa: F401
    except ImportError:
        import pysqlite3

        sys.modules["sqlite3"] = pysqlite3

    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
else:
    engine = create_engine(DATABASE_URL, pool_pre_ping=True)

SessionLocal = sessionmaker(bind=engine)

Base = declarative_base()


class CarroSQL(Base):
    __tablename__ = "carros"
    id = Column(Integer, primary_key=True, index=True)
    marca = Column(String)
    modelo = Column(String)
    ano = Column(Integer)
    documento_key = Column(String, nullable=True)


def ensure_sqlite_schema():
    # Em ambientes de lab, garante a coluna sem migradores externos
    with engine.connect() as conn:
        cols = conn.execute(text("PRAGMA table_info(carros)")).fetchall()
        col_names = {row[1] for row in cols}
        if "documento_key" not in col_names:
            conn.execute(text("ALTER TABLE carros ADD COLUMN documento_key VARCHAR"))


# Inicialização
Base.metadata.create_all(bind=engine)
if IS_SQLITE:
    ensure_sqlite_schema()


class CarroSchema(BaseModel):
    marca: str
    modelo: str
    ano: int
    documento_key: str | None = None

    class Config:
        from_attributes = True  # Útil para converter de SQL para Pydantic
