from pathlib import Path
import sys

import pytest

# Garante que app/api esteja no sys.path para importar main.py
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import main


def test_get_s3_client_missing_creds(monkeypatch):
    """Deve lançar erro quando credenciais S3 não estão configuradas."""
    monkeypatch.setattr(main, "S3_ACCESS_KEY", "")
    monkeypatch.setattr(main, "S3_SECRET_KEY", "")

    with pytest.raises(RuntimeError):
        main.get_s3_client()
