# Usando uma imagem leve e estável
FROM python:3.11-slim

WORKDIR /app

# Instala dependências de sistema se necessário
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential && \
    rm -rf /var/lib/apt/lists/*

# Copia apenas o requirements primeiro (melhora o cache do Docker)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia o restante do código
COPY . .

# Porta padrão do FastAPI
EXPOSE 8000

# Comando para rodar (host 0.0.0.0 é obrigatório em containers)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]