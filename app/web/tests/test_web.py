import types
from pathlib import Path
import sys
import io

import pytest
import requests

# Garante que app/web esteja no sys.path para importar app.py
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import app as web_app


@pytest.fixture()
def client():
    web_app.app.config.update({"TESTING": True})
    return web_app.app.test_client()


def test_healthz(client):
    """Deve retornar status ok no endpoint de healthcheck."""
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "ok"}


def test_index_success(monkeypatch, client):
    """Deve renderizar a home quando a API responde com sucesso."""
    def fake_get(url, timeout):
        assert url == web_app.API_URL
        assert timeout == web_app.TIMEOUT
        return types.SimpleNamespace(status_code=200, json=lambda: [{"id": "1"}])

    monkeypatch.setattr(requests, "get", fake_get)

    resp = client.get("/")
    assert resp.status_code == 200


def test_index_request_error(monkeypatch, client):
    """Deve renderizar a home mesmo quando a API falha."""
    def fake_get(_url, timeout=None):
        raise requests.exceptions.RequestException("boom")

    monkeypatch.setattr(requests, "get", fake_get)

    resp = client.get("/")
    assert resp.status_code == 200


def test_cadastrar_post(monkeypatch, client):
    """Deve enviar POST para API e redirecionar ao finalizar."""
    called = {}

    def fake_post(url, json=None, files=None, timeout=None):
        called.setdefault("urls", []).append(url)
        return types.SimpleNamespace(status_code=200, json=lambda: {"id": None})

    monkeypatch.setattr(requests, "post", fake_post)

    resp = client.post(
        "/cadastrar",
        data={"marca": "A", "modelo": "B", "ano": "2020"},
        content_type="multipart/form-data",
    )
    assert resp.status_code == 302
    assert called["urls"][0] == web_app.API_URL


def test_cadastrar_with_upload(monkeypatch, client):
    """Deve enviar upload de documento quando API retorna id."""
    called = {"urls": []}

    def fake_post(url, json=None, files=None, timeout=None):
        called["urls"].append(url)
        if url == web_app.API_URL:
            return types.SimpleNamespace(status_code=200, json=lambda: {"id": "abc"})
        return types.SimpleNamespace(status_code=200, json=lambda: {})

    monkeypatch.setattr(requests, "post", fake_post)

    data = {
        "marca": "A",
        "modelo": "B",
        "ano": "2020",
        "documento": (io.BytesIO(b"hello"), "doc.txt", "text/plain"),
    }

    resp = client.post("/cadastrar", data=data, content_type="multipart/form-data")

    assert resp.status_code == 302
    assert called["urls"] == [web_app.API_URL, f"{web_app.API_URL}/abc/documento"]


def test_excluir(monkeypatch, client):
    """Deve enviar DELETE para API e redirecionar."""
    called = {}

    def fake_delete(url, timeout):
        called["url"] = url
        return types.SimpleNamespace(status_code=200, json=lambda: {})

    monkeypatch.setattr(requests, "delete", fake_delete)

    resp = client.get("/excluir/123")
    assert resp.status_code == 302
    assert called["url"] == f"{web_app.API_URL}/123"
    
