#!/usr/bin/env python3

import requests
import random
from bs4 import BeautifulSoup
import time

# Lista de User-Agents para evitar bloqueios
user_agent_list = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36',
    'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
]

# Criação da sessão para manter a conexão persistente
session = requests.Session()

# Definir cabeçalhos
headers = {
    'User-Agent': random.choice(user_agent_list),
    'Accept-Language': 'en-US,en;q=0.9',
    'Referer': 'http://downdetector.com.br',  # Referência à página de origem
}

# Proxies (opcional, caso queira usar proxies)
# proxies = {
#     'http': 'http://proxy.example.com:8080',
#     'https': 'https://proxy.example.com:8080',
# }

# Substitua pelo site que deseja testar
site = "correios"

url = f"http://downdetector.com.br/fora-do-ar/{site}/"
print(f"Testando URL: {url}")

time.sleep(2)  # Espera entre as requisições para evitar bloqueios rápidos

try:
    # Enviar a requisição com os cabeçalhos configurados
    response = session.get(url, headers=headers)  # Adicione proxies=proxies se necessário
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        print("Conteúdo da resposta (limite de 500 caracteres):")
        print(response.text[:500])  # Limita a saída para evitar muito texto
    else:
        print(f"Erro ao acessar a página, Status Code: {response.status_code}")
        
except Exception as e:
    print(f"Erro na requisição: {e}")

