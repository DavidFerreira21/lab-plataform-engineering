from flask import Flask, render_template, request, redirect
import requests
import os
import logging
import sys

app = Flask(__name__, template_folder='app_templates')

# Configuração via variáveis de ambiente (Padrão de Plataforma)
API_URL = os.getenv("API_URL", "http://127.0.0.1:8000/carros")
DEBUG_MODE = os.getenv("FLASK_DEBUG", "false").lower() == "true"
TIMEOUT = 5  # Segundos

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger("web")

@app.route('/')
def index():
    logger.info("GET /")
    try:
        # Adicionado timeout para satisfazer o Bandit B113
        response = requests.get(API_URL, timeout=TIMEOUT)
        carros = response.json()
    except requests.exceptions.RequestException as exc:
        logger.warning("API request failed: %s", exc)
        carros = []
    return render_template('index.html', carros=carros)

@app.route('/cadastrar', methods=['POST'])
def cadastrar():
    logger.info("POST /cadastrar")
    dados = {
        "marca": request.form.get("marca"),
        "modelo": request.form.get("modelo"),
        "ano": int(request.form.get("ano"))
    }
    try:
        requests.post(API_URL, json=dados, timeout=TIMEOUT)
    except requests.exceptions.RequestException as exc:
        logger.warning("API request failed: %s", exc)
    return redirect('/')

@app.route('/excluir/<id>')
def excluir(id):
    logger.info("GET /excluir/%s", id)
    try:
        requests.delete(f"{API_URL}/{id}", timeout=TIMEOUT)
    except requests.exceptions.RequestException as exc:
        logger.warning("API request failed: %s", exc)
    return redirect('/')
if __name__ == '__main__':
    # O host 0.0.0.0 é necessário para o Docker/K8s, 
    # usamos # nosec B104 para informar ao Bandit que isso é intencional.
    app.run(host='0.0.0.0', port=5000, debug=DEBUG_MODE)  # nosec B104
