FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

# O Flask precisa rodar em 0.0.0.0 para ser acessível fora do container
CMD ["python", "app.py"]