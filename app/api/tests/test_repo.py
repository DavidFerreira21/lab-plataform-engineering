from pathlib import Path
import sys

import pytest

# Garante que app/api esteja no sys.path para importar main.py
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import main


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
        obj.id = 123


class FakeCarro:
    def __init__(self, **kwargs):
        self.id = None
        self.marca = kwargs.get("marca")
        self.modelo = kwargs.get("modelo")
        self.ano = kwargs.get("ano")
        self.documento_key = kwargs.get("documento_key")


def test_listar_sql(monkeypatch):
    fake_session = FakeSession(query_obj=FakeQuery(all_result=[{"ok": True}]))
    monkeypatch.setattr(main, "SessionLocal", lambda: fake_session)

    result = main.CarroRepo.listar()

    assert result == [{"ok": True}]


def test_salvar_sql(monkeypatch):
    fake_session = FakeSession()
    monkeypatch.setattr(main, "SessionLocal", lambda: fake_session)
    monkeypatch.setattr(main, "CarroSQL", FakeCarro)

    carro_id = main.CarroRepo.salvar({"marca": "A", "modelo": "B", "ano": 2020})

    assert carro_id == "123"
    assert isinstance(fake_session.added, FakeCarro)
    assert fake_session.committed is True


def test_deletar_sql(monkeypatch):
    carro = FakeCarro(marca="A")
    fake_session = FakeSession(query_obj=FakeQuery(first_result=carro))
    monkeypatch.setattr(main, "SessionLocal", lambda: fake_session)

    main.CarroRepo.deletar(1)

    assert fake_session.deleted is carro
    assert fake_session.committed is True


def test_atualizar_documento_sql(monkeypatch):
    carro = FakeCarro(marca="A")
    fake_session = FakeSession(query_obj=FakeQuery(first_result=carro))
    monkeypatch.setattr(main, "SessionLocal", lambda: fake_session)

    main.CarroRepo.atualizar_documento(1, "k")

    assert carro.documento_key == "k"
    assert fake_session.committed is True


def test_delete_endpoint_converte_id_para_int(monkeypatch):
    captured = {}

    def fake_delete(carro_id):
        captured["id"] = carro_id

    monkeypatch.setattr(main.CarroRepo, "deletar", fake_delete)

    response = main.delete_carro("9")

    assert captured["id"] == 9
    assert response["status"] == "removido"


def test_delete_endpoint_id_invalido_levanta_value_error():
    with pytest.raises(ValueError):
        main.delete_carro("abc")
