from flask import Flask, render_template, request, redirect, g
import requests
import os
import logging
import sys
import json
import time

app = Flask(__name__, template_folder='app_templates')

# Configuração via variáveis de ambiente (Padrão de Plataforma)
API_URL = os.getenv("API_URL", "http://127.0.0.1:8000/carros")
DEBUG_MODE = os.getenv("FLASK_DEBUG", "false").lower() == "true"
TIMEOUT = 5  # Segundos

logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger("web")

def log_json(level, message, **fields):
    payload = {"level": level, "message": message, **fields}
    logger.log(level, json.dumps(payload, ensure_ascii=True))

@app.before_request
def start_timer():
    g.start_time = time.perf_counter()

@app.after_request
def log_response(response):
    duration_ms = round((time.perf_counter() - g.start_time) * 1000, 2)
    log_json(
        logging.INFO,
        "request",
        method=request.method,
        path=request.path,
        status_code=response.status_code,
        duration_ms=duration_ms,
    )
    return response

@app.route('/')
def index():
    try:
        # Adicionado timeout para satisfazer o Bandit B113
        api_start = time.perf_counter()
        response = requests.get(API_URL, timeout=TIMEOUT)
        api_duration_ms = round((time.perf_counter() - api_start) * 1000, 2)
        log_json(
            logging.INFO,
            "api_request",
            method="GET",
            url=API_URL,
            status_code=response.status_code,
            duration_ms=api_duration_ms,
        )
        carros = response.json()
    except requests.exceptions.RequestException as exc:
        log_json(
            logging.WARNING,
            "api_request_error",
            method="GET",
            url=API_URL,
            error=str(exc),
        )
        carros = []
    return render_template('index.html', carros=carros)

@app.route('/cadastrar', methods=['POST'])
def cadastrar():
    dados = {
        "marca": request.form.get("marca"),
        "modelo": request.form.get("modelo"),
        "ano": int(request.form.get("ano"))
    }
    try:
        api_start = time.perf_counter()
        response = requests.post(API_URL, json=dados, timeout=TIMEOUT)
        api_duration_ms = round((time.perf_counter() - api_start) * 1000, 2)
        log_json(
            logging.INFO,
            "api_request",
            method="POST",
            url=API_URL,
            status_code=response.status_code,
            duration_ms=api_duration_ms,
        )
    except requests.exceptions.RequestException as exc:
        log_json(
            logging.WARNING,
            "api_request_error",
            method="POST",
            url=API_URL,
            error=str(exc),
        )
    return redirect('/')

@app.route('/excluir/<id>')
def excluir(id):
    try:
        url = f"{API_URL}/{id}"
        api_start = time.perf_counter()
        response = requests.delete(url, timeout=TIMEOUT)
        api_duration_ms = round((time.perf_counter() - api_start) * 1000, 2)
        log_json(
            logging.INFO,
            "api_request",
            method="DELETE",
            url=url,
            status_code=response.status_code,
            duration_ms=api_duration_ms,
        )
    except requests.exceptions.RequestException as exc:
        log_json(
            logging.WARNING,
            "api_request_error",
            method="DELETE",
            url=f"{API_URL}/{id}",
            error=str(exc),
        )
    return redirect('/')
if __name__ == '__main__':
    # O host 0.0.0.0 é necessário para o Docker/K8s, 
    # usamos # nosec B104 para informar ao Bandit que isso é intencional.
    app.run(host='0.0.0.0', port=5000, debug=DEBUG_MODE)  # nosec B104
