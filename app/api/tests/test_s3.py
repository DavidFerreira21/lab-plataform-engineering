import sys
from pathlib import Path

# Garante que app/api esteja no sys.path para importar main.py
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import main


def test_get_s3_client_missing_creds_uses_default_chain(monkeypatch):
    """Sem credenciais explicitas, deve usar a cadeia default do boto3 (IRSA)."""
    monkeypatch.setattr(main, "S3_ACCESS_KEY", "")
    monkeypatch.setattr(main, "S3_SECRET_KEY", "")
    monkeypatch.setattr(main, "S3_ENDPOINT", "https://s3.amazonaws.com")
    monkeypatch.setattr(main, "S3_REGION", "us-east-1")
    monkeypatch.setattr(main, "S3_USE_SSL", True)

    called = {}

    def fake_client(service, **kwargs):
        called["service"] = service
        called["kwargs"] = kwargs
        return object()

    monkeypatch.setattr(main.boto3, "client", fake_client)
    main.get_s3_client()

    assert called["service"] == "s3"
    assert called["kwargs"]["endpoint_url"] == "https://s3.amazonaws.com"
    assert called["kwargs"]["region_name"] == "us-east-1"
    assert called["kwargs"]["use_ssl"] is True
    assert "aws_access_key_id" not in called["kwargs"]
    assert "aws_secret_access_key" not in called["kwargs"]


def test_get_s3_client_with_static_creds(monkeypatch):
    """Com credenciais explicitas, deve enviar access key e secret key para boto3."""
    monkeypatch.setattr(main, "S3_ACCESS_KEY", "test-access")
    monkeypatch.setattr(main, "S3_SECRET_KEY", "test-secret")
    monkeypatch.setattr(main, "S3_ENDPOINT", "http://minio:9000")
    monkeypatch.setattr(main, "S3_REGION", "us-east-1")
    monkeypatch.setattr(main, "S3_USE_SSL", False)

    called = {}

    def fake_client(service, **kwargs):
        called["service"] = service
        called["kwargs"] = kwargs
        return object()

    monkeypatch.setattr(main.boto3, "client", fake_client)
    main.get_s3_client()

    assert called["service"] == "s3"
    assert called["kwargs"]["aws_access_key_id"] == "test-access"
    assert called["kwargs"]["aws_secret_access_key"] == "test-secret"
