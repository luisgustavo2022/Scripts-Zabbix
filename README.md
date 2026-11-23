# Zabbix External Scripts

Coleção de *external scripts* para Zabbix que monitoram serviços em nuvem (Microsoft 365, Downdetector, KingHost), compartilhamentos SMB (arquivos de retorno bancário e backups) e um banco de dados via ODBC.

![Zabbix](https://img.shields.io/badge/Zabbix-external%20scripts-D40000?logo=zabbix&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-5.x-4EAA25?logo=gnubash&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.x-3776AB?logo=python&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-7.x-5391FE?logo=powershell&logoColor=white)
![License](https://img.shields.io/badge/licen%C3%A7a-MIT-blue)
![Status](https://img.shields.io/badge/status-em%20uso-brightgreen)
![Version](https://img.shields.io/badge/vers%C3%A3o-0.1.0-lightgrey)

---

## 📑 Resumo dos scripts

| Script | Linguagem | Tipo no Zabbix | O que faz | Retorno |
|---|---|---|---|---|
| `check_email_netfactor.sh` | Bash | External check | Verifica via Microsoft Graph se um e-mail com assunto específico chegou numa caixa nas últimas N horas | `1` encontrado · `0` não encontrado · `-1` erro |
| `exchange_zabbix.sh` | Bash | Trapper (via `zabbix_sender`) | Coleta o tamanho de todas as caixas do Exchange Online e envia LLD + métricas ao Zabbix | Saída do `zabbix_sender` |
| `exchange_zabbix.ps1` | PowerShell | Trapper (via `zabbix_sender`) | Versão PowerShell do script acima | Saída do `zabbix_sender` |
| `downdetector.py` | Python | External check | Consulta o status de um serviço no Downdetector Brasil | `1` ok · `2` alerta · `3` problema · `0` falha |
| `downdetectorDiscovery.py` | Python | LLD (external check) | Gera o JSON de descoberta a partir de `downdetectorlist.list` | JSON LLD |
| `downdetectorlist.list` | Texto | — | Catálogo de serviços do Downdetector (ativo/inativo) | — |
| `downdetectorTeste.py` / `downdetectorTeste2.py` | Python | — (testes manuais) | Testes de requisição ao Downdetector | Texto de diagnóstico |
| `kinghost_monitor.py` | Python | — (chamado pelo wrapper) | Lê a caixa via IMAP e extrai métricas do alerta "risco do seu email ser bloqueado" da KingHost | Linhas `chave:valor` |
| `kinghost_check.sh` | Bash | External check | Wrapper que devolve uma única métrica do `kinghost_monitor.py` | Valor da métrica |
| `scriptteste.py` | Shell (heredoc) | — | Snippet que recria o `kinghost_monitor.py` (duplicado) | — |
| `verificar_retorno.sh` | Bash | External check | Verifica se chegou arquivo de retorno bancário (Bradesco/Grafeno) hoje num compartilhamento SMB | `1` sim · `0` não |
| `verificar_retorno_teste.sh` | Bash | — (teste) | Variante de teste do script acima, em outro compartilhamento | `1` sim · `0` não |
| `qtdRetornoGrafeno.sh` | Bash | External check | Verifica se chegaram pelo menos 20 arquivos de retorno Grafeno hoje | `1` ≥ 20 · `0` < 20 |
| `ultimo_backup.sh` | Bash | External check | Retorna o timestamp do arquivo mais recente numa pasta de backup SMB | Unix timestamp · `0` erro |
| `consulta_saldo_grafeno.sh` | Bash | External check | Soma os saldos positivos de contas na tabela `nfBankAccountsGrafeno` (ODBC) | Número |
| `consulta_duplicidade_grafeno.sh` | Bash | External check | Conta registros duplicados de uma conta na mesma tabela | Número |
| `ipexterno` | Bash | External check | Retorna o IP público sem pontos (ex.: `200123045067`) | Número |

---

## 📋 Sobre o projeto

O Zabbix monitora bem servidores e redes, mas muitos riscos de operação estão **fora** dele: um e-mail de importação que não chegou, um arquivo de retorno do banco que não caiu no compartilhamento, um backup que parou de rodar, um provedor de e-mail prestes a bloquear a conta por excesso de envios, ou um serviço externo (WhatsApp, AWS, Gmail…) fora do ar.

Estes scripts transformam cada uma dessas situações em um **valor numérico simples** que o Zabbix consegue coletar, guardar em histórico e usar em *triggers*. A maioria roda como *external check* (o Zabbix executa o script e lê a saída); os scripts do Exchange rodam por agendamento e empurram dados com `zabbix_sender`.

---

## ✨ Funcionalidades

- **Microsoft 365 / Graph API**
  - Checagem de chegada de e-mail por assunto e janela de tempo, com log próprio e rotação simples (`check_email_netfactor.sh`)
  - Descoberta automática (LLD) de caixas do Exchange Online e coleta do armazenamento usado (`exchange_zabbix.*`)
- **Downdetector**
  - Status de serviços externos mapeado para `1/2/3`
  - LLD dos serviços marcados como ativos no arquivo `.list`
  - Uso de `cloudscraper` ou `requests` com *User-Agent* aleatório, conforme a versão do OpenSSL
- **KingHost**
  - Leitura IMAP dos 10 e-mails mais recentes do remetente `nao-responda@kinghost.com.br`
  - Extração de envios, limite, percentual de uso, destinatários e conta que mais enviou
- **Compartilhamentos SMB**
  - Presença de arquivos de retorno do dia (Bradesco `COB_237_*.txt`, Grafeno `Nf_charge*.ret*`)
  - Quantidade mínima de retornos Grafeno no dia
  - Data do último backup como *timestamp*
- **Banco de dados (ODBC / `isql`)**
  - Saldo consolidado e checagem de duplicidade de conta na tabela `nfBankAccountsGrafeno`
- **Rede**
  - IP público atual (útil para detectar troca de IP do link)

---

## 🧰 Tecnologias utilizadas

| Categoria | Itens |
|---|---|
| Linguagens | Bash, Python 3, PowerShell |
| Monitoramento | Zabbix (external checks, LLD, trapper/`zabbix_sender`) |
| APIs | Microsoft Graph (OAuth2 *client credentials*), ipinfo.io |
| Python | `beautifulsoup4`, `requests`, `cloudscraper`; stdlib: `imaplib`, `email`, `json`, `re`, `ssl` |
| CLI | `curl`, `jq`, `smbclient` (Samba), `isql` (unixODBC), `awk`, `sed` |
| Banco | SQL Server via ODBC <!-- TODO: confirmar SGBD (sintaxe `ISNULL`/`SET NOCOUNT` indica SQL Server) --> |

---

## 📁 Estrutura do projeto

```text
externalscripts/
├── check_email_netfactor.sh        # Graph API: e-mail chegou?
├── exchange_zabbix.sh              # Graph API: tamanho das caixas (Bash)
├── exchange_zabbix.ps1             # Graph API: tamanho das caixas (PowerShell)
├── downdetector.py                 # Status de um serviço no Downdetector
├── downdetectorDiscovery.py        # LLD dos serviços ativos
├── downdetectorlist.list           # Catálogo de serviços (ativo;id;nome)
├── downdetectorTeste.py            # Teste manual
├── downdetectorTeste2.py           # Teste manual (com cookie cf_clearance)
├── kinghost_monitor.py             # Métricas do alerta KingHost (IMAP)
├── kinghost_check.sh               # Wrapper: devolve uma métrica
├── scriptteste.py                  # Duplicata do kinghost_monitor (heredoc)
├── verificar_retorno.sh            # Retorno bancário do dia (SMB)
├── verificar_retorno_teste.sh      # Variante de teste
├── qtdRetornoGrafeno.sh            # Mínimo de retornos Grafeno no dia
├── ultimo_backup.sh                # Timestamp do último backup (SMB)
├── consulta_saldo_grafeno.sh       # Saldo consolidado (ODBC)
├── consulta_duplicidade_grafeno.sh # Duplicidade de conta (ODBC)
└── ipexterno                       # IP público sem pontos
```

---

## ⚙️ Pré-requisitos

- **Servidor Zabbix ou Proxy** em Linux, com o diretório de *external scripts* configurado (padrão: `/usr/lib/zabbix/externalscripts`)
- **Bash 4+**, `curl`, `jq`, `awk`, `sed`, GNU `date` e `stat`
- **Python 3** <!-- TODO: confirmar versão mínima (o código usa f-strings → 3.6+) -->
- **Samba client** (`smbclient`) para os scripts SMB
- **unixODBC** (`isql`) + driver ODBC do banco (ex.: `msodbcsql18`) com DSN configurado
- **`zabbix_sender`** para os scripts do Exchange
- **PowerShell 7 (`pwsh`)** apenas se for usar `exchange_zabbix.ps1`
- **App registration no Microsoft Entra ID** com *client secret* e permissões de aplicativo (com consentimento de administrador):
  - `Mail.Read` → `check_email_netfactor.sh`
  - `Reports.Read.All` → `exchange_zabbix.*`
- Acesso de rede do servidor Zabbix aos compartilhamentos SMB, ao banco, a `login.microsoftonline.com`, `graph.microsoft.com`, `imap.kinghost.net`, `downdetector.com.br` e `ipinfo.io`

---

## 🚀 Instalação

1. **Instale as dependências do sistema** (Debian/Ubuntu):

   ```bash
   sudo apt update
   sudo apt install -y curl jq smbclient unixodbc zabbix-sender python3 python3-pip
   ```

2. **Instale as dependências Python** (como o usuário que executa o Zabbix):

   ```bash
   sudo pip3 install beautifulsoup4 requests cloudscraper
   ```

3. **Clone o repositório e copie os scripts**:

   ```bash
   git clone https://github.com/<SEU_USUARIO>/zabbix-external-scripts.git
   sudo cp zabbix-external-scripts/externalscripts/* /usr/lib/zabbix/externalscripts/
   ```

4. **Ajuste dono e permissões**:

   ```bash
   cd /usr/lib/zabbix/externalscripts
   sudo chown zabbix:zabbix *
   sudo chmod 750 *.sh *.py ipexterno
   ```

5. **Crie os arquivos de credenciais** (veja [🔧 Configuração](#-configuração)) e restrinja o acesso:

   ```bash
   sudo chown root:zabbix /etc/zabbix/m365.env /etc/zabbix/grafeno_creds
   sudo chmod 640 /etc/zabbix/m365.env /etc/zabbix/grafeno_creds
   ```

6. **Teste como o usuário `zabbix`** antes de criar os itens:

   ```bash
   sudo -u zabbix /usr/lib/zabbix/externalscripts/check_email_netfactor.sh
   ```

---

## ▶️ Como usar

### External checks no Zabbix

Crie itens do tipo **External check** com a chave no formato `script[param1,param2]`:

| Chave do item | Tipo de informação | Exemplo de saída |
|---|---|---|
| `check_email_netfactor.sh` | Numérico (inteiro) | `1` |
| `downdetector.py[{#SITE_ID}]` | Numérico (inteiro) | `1` |
| `downdetectorDiscovery.py` | Regra de LLD | `{"data":[{"{#SITE_ID}":"whatsapp","{#SITE_NOME}":"Whatsapp"}]}` |
| `kinghost_check.sh[usage_percent]` | Numérico (inteiro) | `85` |
| `kinghost_check.sh[main_account]` | Texto | `<conta@dominio>` |
| `verificar_retorno.sh[bradesco]` | Numérico (inteiro) | `0` |
| `verificar_retorno.sh[grafeno]` | Numérico (inteiro) | `1` |
| `qtdRetornoGrafeno.sh` | Numérico (inteiro) | `1` |
| `ultimo_backup.sh` | Numérico (inteiro, unixtime) | `1763900000` |
| `consulta_saldo_grafeno.sh` | Numérico (float) | `152340.75` |
| `consulta_duplicidade_grafeno.sh` | Numérico (inteiro) | `1` |
| `ipexterno` | Numérico (inteiro) ou texto | `200123045067` |

### Execução manual

```bash
# E-mail chegou nas últimas N horas?
./check_email_netfactor.sh
# 1

# Status de um serviço no Downdetector
python3 downdetector.py whatsapp
# 1

# Descoberta dos serviços ativos
python3 downdetectorDiscovery.py
# {"data": [{"{#SITE_ID}": "amazon-prime-instant-video", "{#SITE_NOME}": "Amazon Prime Video"}, ...]}

# Todas as métricas da KingHost (o debug vai para stderr)
python3 kinghost_monitor.py 2>/dev/null
# alert_detected:1
# emails_sent:350
# limit_emails:400
# usage_percent:87
# recipients_count:900
# limit_recipients:1000
# main_account:<conta@dominio>

# Uma métrica só
./kinghost_check.sh usage_percent
# 87

# Retorno bancário do dia
./verificar_retorno.sh grafeno
# 1
```

### Scripts do Exchange (trapper)

Crie no Zabbix um host com o nome `Exchange365`, uma regra de LLD do tipo **Zabbix trapper** com a chave `exchange.discovery` e um protótipo de item trapper `exchange.mailbox.size[{#MAILBOX}]`. Depois agende a execução:

```bash
# crontab do usuário zabbix — uma vez por dia
15 6 * * * /usr/lib/zabbix/externalscripts/exchange_zabbix.sh >/dev/null 2>&1
```

```powershell
# alternativa em PowerShell 7
pwsh -File ./exchange_zabbix.ps1
```

> O relatório `getMailboxUsageDetail` tem atraso natural de 24–48 h; não há ganho em rodar com frequência maior que diária.

---

## 🔧 Configuração

### `/etc/zabbix/m365.env` — usado por `check_email_netfactor.sh`

```bash
M365_TENANT_ID="<SEU_TENANT_ID>"
M365_CLIENT_ID="<SEU_CLIENT_ID>"
M365_CLIENT_SECRET="<SEU_CLIENT_SECRET>"
M365_MAILBOX="<caixa@dominio.com.br>"
M365_SUBJECT="<ASSUNTO_EXATO_DO_EMAIL>"
M365_JANELA="6"   # opcional: janela em horas (padrão 6)
```

Log em `/var/log/zabbix/check_email_netfactor.log` (rotação automática acima de 100 KB).

### `/etc/zabbix/grafeno_creds` — usado pelos scripts ODBC

```bash
DSN="<NOME_DO_DSN>"
USER="<USUARIO_SOMENTE_LEITURA>"
PASS="<SENHA>"
```

O DSN precisa existir em `/etc/odbc.ini`. A conta consultada em `consulta_duplicidade_grafeno.sh` está fixa na query — substitua por `<NUMERO_DA_CONTA>` ou parametrize.

### Variáveis embutidas nos scripts (devem ser externalizadas)

| Script | Variáveis |
|---|---|
| `exchange_zabbix.sh` / `.ps1` | `TENANT_ID`, `CLIENT_ID`, `CLIENT_SECRET`, `ZABBIX_SERVER`, `ZABBIX_HOST`, `TMP_FILE` |
| `kinghost_monitor.py` | `IMAP_SERVER`, `EMAIL_ACCOUNT`, `EMAIL_PASSWORD` |
| `verificar_retorno*.sh`, `qtdRetornoGrafeno.sh` | `SERVIDOR`, `COMPARTILHAMENTO`, `USUARIO`, `WORKGROUP`, `SENHA` |
| `ultimo_backup.sh` | `SERVIDOR`, `COMPARTILHAMENTO`, `PASTA`, `USUARIO`, `SENHA` |
| `downdetectorDiscovery.py` | `FILE` (caminho do `.list`) |

Sugestão: mova todas para arquivos em `/etc/zabbix/*.env` (como já faz o `check_email_netfactor.sh`) e use um arquivo de credenciais do Samba (`smbclient -A /etc/zabbix/smb_creds`) em vez de senha na linha de comando.

### `downdetectorlist.list`

Formato `ativo;id_no_downdetector;nome_exibido`. Só linhas com `1` entram na descoberta:

```text
1;whatsapp;Whatsapp
0;teams;Microsoft Teams
```

---

## ⚠️ Pontos de atenção

- **Credenciais em texto puro.** Vários scripts têm segredos embutidos (client secret do Entra ID, senha IMAP, senha de administrador SMB). Remova-os antes de publicar e troque os valores que já foram expostos.
- **Bug nos dias 1 a 9 do mês** (`verificar_retorno.sh`, `qtdRetornoGrafeno.sh`): o `tr -s ' '` transforma `Nov  3` em `Nov 3`, mas a listagem do `smbclient` mantém dois espaços, então o `grep` não encontra nada e o script retorna `0`. <!-- TODO: confirmar no ambiente -->
- **Dependência de locale:** `verificar_retorno.sh` e `verificar_retorno_teste.sh` usam `date "+%b"` sem `LC_ALL=C`; num servidor em pt-BR o mês sai como `nov` e não casa com a saída do `smbclient`.
- **`ultimo_backup.sh` ordena datas como texto** (`Dec` vem antes de `Nov`), então pode escolher o arquivo errado. A linha final `blocks of size…` do `smbclient` também entra na ordenação. A senha é passada como argumento posicional e fica visível no `ps`.
- **`exchange_zabbix.ps1` tem erros de sintaxe** (espaços faltando em `-lt$CsvLines`, `-and$StorageUsed`, `-FilePath$TempFile`, `-i$TempFile` e um `\vert{}` no lugar do pipe `|`). Não roda como está.
- **Colunas diferentes entre as versões do Exchange:** o `.sh` lê o 9º campo e o `.ps1` lê o 11º como armazenamento usado. <!-- TODO: confirmar qual coluna do CSV corresponde a "Storage Used (Byte)" --> O `awk -F','` do `.sh` também quebra se algum nome tiver vírgula.
- **Relatórios do M365 podem vir anonimizados:** se a opção de privacidade de relatórios estiver ativa no tenant, os UPNs vêm como hash.
- **Downdetector é frágil:** o site usa proteção Cloudflare e muda o HTML; o *fallback* por regex lança `IndexError` se não encontrar o padrão. Os scripts `downdetectorTeste*.py` são apenas para diagnóstico.
- **`kinghost_check.sh` faz um login IMAP por métrica** (7 itens = 7 logins por ciclo). Considere rodar o `kinghost_monitor.py` uma vez e enviar tudo por `zabbix_sender`, ou usar itens dependentes.
- **`qtdRetornoGrafeno.sh`:** o comentário diz "10 ou mais", mas o limite no código é 20.
- **`consulta_duplicidade_grafeno.sh`:** o comentário do cabeçalho menciona `consulta_saldo_grafeno.sh` (cópia).
- **`scriptteste.py`** não é Python: é um heredoc shell que recria o `kinghost_monitor.py`. Pode ser removido.
- **Timeout:** o Zabbix mata external checks que passam do `Timeout` configurado (padrão 3 s). Os scripts de Graph e IMAP podem precisar de um valor maior.

---

## 📸 Exemplos

Trigger para e-mail que não chegou:

```text
last(/Servidor/check_email_netfactor.sh)=0
```

Trigger para backup com mais de 26 horas:

```text
now() - last(/Servidor/ultimo_backup.sh) > 26h
```

Trigger para uso de envios da KingHost acima de 80%:

```text
last(/Servidor/kinghost_check.sh[usage_percent])>80
```

<!-- TODO: adicionar prints dos dashboards/gráficos do Zabbix -->

---

## 🤝 Contribuindo

1. Faça um **fork** do projeto
2. Crie uma branch para sua alteração:
   ```bash
   git checkout -b feature/minha-melhoria
   ```
3. Faça commit das mudanças:
   ```bash
   git commit -m "feat: descreve a melhoria"
   ```
4. Envie para o seu fork:
   ```bash
   git push origin feature/minha-melhoria
   ```
5. Abra um **Pull Request**

Nunca inclua credenciais reais em commits, issues ou PRs.

---

## 📄 Licença

Distribuído sob a licença **MIT**. Veja o arquivo [`LICENSE`](LICENSE) para mais detalhes.

---

## 👤 Autor

**[Seu Nome]**

- [GitHub](https://github.com/<SEU_USUARIO>)
- [LinkedIn](https://www.linkedin.com/in/<SEU_PERFIL>)

---

## ⭐ Agradecimentos

- **Gabriel Padilha**, autor original do `downdetector.py` (crédito mantido no cabeçalho do script)
- Documentação do [Zabbix](https://www.zabbix.com/documentation) e do [Microsoft Graph](https://learn.microsoft.com/graph/)
