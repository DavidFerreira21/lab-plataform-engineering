from flask import Flask, render_template, request, redirect
import requests

app = Flask(__name__)
API_URL = "http://127.0.0.1:8000/carros"

@app.route('/')
def index():
    # Busca a lista de carros na API
    response = requests.get(API_URL)
    carros = response.json()
    return render_template('index.html', carros=carros)

@app.route('/cadastrar', methods=['POST'])
def cadastrar():
    dados = {
        "marca": request.form.get("marca"),
        "modelo": request.form.get("modelo"),
        "ano": int(request.form.get("ano"))
    }
    requests.post(API_URL, json=dados)
    return redirect('/')

@app.route('/excluir/<int:id>')
def excluir(id):
    requests.delete(f"{API_URL}/{id}")
    return redirect('/')

if __name__ == '__main__':
    app.run(port=5000, debug=True)