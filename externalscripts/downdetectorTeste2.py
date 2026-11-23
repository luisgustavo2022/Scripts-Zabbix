#!/usr/bin/env python3

import requests
import random
import time
from bs4 import BeautifulSoup

# Lista de User-Agents para evitar bloqueios
user_agent_list = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.51 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edge/92.0.902.67',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.96 Safari/537.36'
]

# Criação da sessão para manter cookies e headers
session = requests.Session()

# Definir cabeçalhos para simular um navegador real
headers = {
    'User-Agent': random.choice(user_agent_list),
    'Accept-Language': 'en-US,en;q=0.9,pt-BR;q=0.8',
    'Referer': 'https://www.google.com/',  # Simula uma pesquisa no Google antes de acessar
    'Upgrade-Insecure-Requests': '1',
    'Connection': 'keep-alive'
}

# Simular cookies (obtidos manualmente pelo navegador no site)
cookies = {
    'cf_clearance': 'SEU_VALOR_AQUI',  # Substitua pelo valor real do cookie
}

# Substitua pelo serviço que deseja testar no Downdetector
site = "whatsapp"
url = f"https://downdetector.com.br/fora-do-ar/{site}/"

print(f"Testando URL: {url}")

time.sleep(random.uniform(1, 3))  # Espera aleatória para parecer mais natural

try:
    # Enviar requisição com cabeçalhos e cookies
    response = session.get(url, headers=headers, cookies=cookies)
    print(f"Status Code: {response.status_code}")

    if response.status_code == 200:
        # Parsear o HTML com BeautifulSoup
        soup = BeautifulSoup(response.text, 'html.parser')

        # Tentar encontrar uma mensagem de status
        status_message = soup.find('h1')
        if status_message:
            print(f"Status do serviço: {status_message.text.strip()}")
        else:
            print("Não foi possível extrair o status do serviço.")

    elif response.status_code == 403:
        print("Acesso bloqueado (403). Tente atualizar os cookies manualmente ou usar Selenium.")

    else:
        print(f"Erro ao acessar a página. Código: {response.status_code}")

except requests.exceptions.RequestException as e:
    print(f"Erro na requisição: {e}")

