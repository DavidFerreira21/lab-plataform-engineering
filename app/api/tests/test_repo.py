import types
from pathlib import Path
import sys

import pytest

# Garante que app/api esteja no sys.path para importar main.py
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import main


class FakeMongoCollection:
    def __init__(self, find_result=None):
        self.find_result = find_result or []
        self.inserted = None
        self.deleted = None
        self.updated = None

    def find(self):
        return list(self.find_result)

    def insert_one(self, doc):
        self.inserted = doc
        return types.SimpleNamespace(inserted_id="abc123")

    def delete_one(self, query):
        self.deleted = query

    def update_one(self, query, update):
        self.updated = (query, update)


class FakeQuery:
    def __init__(self, all_result=None, first_result=None):
        self._all = all_result or []
        self._first = first_result
        self.filter_args = None

    def all(self):
        return self._all

    def filter(self, *args, **kwargs):
        self.filter_args = (args, kwargs)
        return self

    def first(self):
        return self._first


class FakeSession:
    def __init__(self, query_obj=None):
        self.query_obj = query_obj or FakeQuery()
        self.added = None
        self.deleted = None
        self.committed = False

    def query(self, _model):
        return self.query_obj

    def add(self, obj):
        self.added = obj

    def delete(self, obj):
        self.deleted = obj

    def commit(self):
        self.committed = True

    def refresh(self, obj):
        # Simula autoincremento
        obj.id = 123


class FakeCarro:
    def __init__(self, **kwargs):
        self.id = None
        self.marca = kwargs.get("marca")
        self.modelo = kwargs.get("modelo")
        self.ano = kwargs.get("ano")
        self.documento_key = kwargs.get("documento_key")


@pytest.fixture(autouse=True)
def reset_globals(monkeypatch):
    # Garantir que cada teste controle o modo
    monkeypatch.setattr(main, "USE_MONGO", False)


def test_listar_mongo_converte_id(monkeypatch):
    """Deve converter _id do Mongo em id string no retorno."""
    monkeypatch.setattr(main, "USE_MONGO", True)
    fake = FakeMongoCollection(find_result=[{"_id": 1, "marca": "A"}])
    monkeypatch.setattr(main, "collection", fake)

    result = main.CarroRepo.listar()

    assert result[0]["id"] == "1"
    assert "_id" in result[0]


def test_listar_sql(monkeypatch):
    """Deve listar registros via SQLAlchemy quando USE_MONGO=False."""
    fake_session = FakeSession(query_obj=FakeQuery(all_result=[{"ok": True}]))
    monkeypatch.setattr(main, "SessionLocal", lambda: fake_session)

    result = main.CarroRepo.listar()

    assert result == [{"ok": True}]


def test_salvar_mongo(monkeypatch):
    """Deve inserir no Mongo e retornar o inserted_id como string."""
    monkeypatch.setattr(main, "USE_MONGO", True)
    fake = FakeMongoCollection()
    monkeypatch.setattr(main, "collection", fake)

    carro_id = main.CarroRepo.salvar({"marca": "A"})

    assert carro_id == "abc123"
    assert fake.inserted == {"marca": "A"}


def test_salvar_sql(monkeypatch):
    """Deve persistir no SQLite e retornar id do objeto criado."""
    fake_session = FakeSession()
    monkeypatch.setattr(main, "SessionLocal", lambda: fake_session)
    monkeypatch.setattr(main, "CarroSQL", FakeCarro)

    carro_id = main.CarroRepo.salvar({"marca": "A", "modelo": "B", "ano": 2020})

    assert carro_id == "123"
    assert isinstance(fake_session.added, FakeCarro)
    assert fake_session.committed is True


def test_deletar_mongo(monkeypatch):
    """Deve remover no Mongo usando o _id informado."""
    monkeypatch.setattr(main, "USE_MONGO", True)
    fake = FakeMongoCollection()
    monkeypatch.setattr(main, "collection", fake)

    main.CarroRepo.deletar("507f1f77bcf86cd799439011")

    assert fake.deleted is not None
    assert "_id" in fake.deleted


def test_deletar_sql(monkeypatch):
    """Deve remover no SQLite quando encontrar o registro."""
    carro = FakeCarro(marca="A")
    fake_session = FakeSession(query_obj=FakeQuery(first_result=carro))
    monkeypatch.setattr(main, "SessionLocal", lambda: fake_session)

    main.CarroRepo.deletar(1)

    assert fake_session.deleted is carro
    assert fake_session.committed is True


def test_atualizar_documento_mongo(monkeypatch):
    """Deve atualizar documento_key no Mongo para o carro."""
    monkeypatch.setattr(main, "USE_MONGO", True)
    fake = FakeMongoCollection()
    monkeypatch.setattr(main, "collection", fake)

    main.CarroRepo.atualizar_documento("507f1f77bcf86cd799439011", "k")

    query, update = fake.updated
    assert "_id" in query
    assert update == {"$set": {"documento_key": "k"}}


def test_atualizar_documento_sql(monkeypatch):
    """Deve atualizar documento_key no SQLite para o carro."""
    carro = FakeCarro(marca="A")
    fake_session = FakeSession(query_obj=FakeQuery(first_result=carro))
    monkeypatch.setattr(main, "SessionLocal", lambda: fake_session)

    main.CarroRepo.atualizar_documento(1, "k")

    assert carro.documento_key == "k"
    assert fake_session.committed is True
