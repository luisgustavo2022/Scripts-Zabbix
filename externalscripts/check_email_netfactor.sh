#!/bin/bash
# Zabbix External Check - verifica se o e-mail do NetFactor chegou (Graph API)
# Retorno: 1 = encontrado | 0 = não encontrado | -1 = erro técnico

source /etc/zabbix/m365.env

: "${M365_TENANT_ID:?Erro: M365_TENANT_ID não definida}"
: "${M365_CLIENT_ID:?Erro: M365_CLIENT_ID não definida}"
: "${M365_CLIENT_SECRET:?Erro: M365_CLIENT_SECRET não definida}"
: "${M365_MAILBOX:?Erro: M365_MAILBOX não definida}"
: "${M365_SUBJECT:?Erro: M365_SUBJECT não definida}"

JANELA="${M365_JANELA:-6}"
LOG_FILE="/var/log/zabbix/check_email_netfactor.log"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null
}

# Rotação simples do log (> 100 KB mantém os últimos 50 KB)
if [ -f "$LOG_FILE" ] && [ "$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)" -gt 102400 ]; then
    tail -c 51200 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

log_msg "=== Verificação iniciada ==="

# 1. Token
TOKEN_RESP=$(curl -s -S --max-time 15 -X POST \
    "https://login.microsoftonline.com/${M365_TENANT_ID}/oauth2/v2.0/token" \
    -d "client_id=${M365_CLIENT_ID}" \
    -d "client_secret=${M365_CLIENT_SECRET}" \
    -d "scope=https://graph.microsoft.com/.default" \
    -d "grant_type=client_credentials" 2>&1)

TOKEN=$(echo "$TOKEN_RESP" | jq -r '.access_token // empty' 2>/dev/null)

if [ -z "$TOKEN" ]; then
    TOKEN_ERR=$(echo "$TOKEN_RESP" | jq -r '.error_description // .error // empty' 2>/dev/null)
    [ -z "$TOKEN_ERR" ] && TOKEN_ERR="$TOKEN_RESP"
    log_msg "ERRO: Não conseguiu token - ${TOKEN_ERR:0:300}"
    echo "-1"
    exit 0
fi

log_msg "Token: OK"

# 2. Data (UTC)
DESDE=$(date -u -d "-${JANELA} hours" +"%Y-%m-%dT%H:%M:%SZ")
log_msg "Período: últimas ${JANELA}h (desde $DESDE)"
log_msg "Caixa: $M365_MAILBOX"
log_msg "Assunto: $M365_SUBJECT"

# 3. Request
log_msg "Enviando requisição..."

# Escapa aspas simples do assunto (OData usa '' para escapar)
SUBJECT_ESC="${M365_SUBJECT//\'/\'\'}"
FILTER="receivedDateTime ge ${DESDE} and subject eq '${SUBJECT_ESC}'"

# $orderby é obrigatório quando o filtro usa mais de uma propriedade
# (evita o erro InefficientFilter). A propriedade do orderby deve ser a
# primeira do filtro. $select evita trazer corpo do e-mail.
RESULT=$(curl -s -S --max-time 20 -G \
    "https://graph.microsoft.com/v1.0/users/${M365_MAILBOX}/messages" \
    --data-urlencode "\$filter=${FILTER}" \
    --data-urlencode "\$orderby=receivedDateTime desc" \
    --data-urlencode "\$select=id,receivedDateTime" \
    --data-urlencode "\$top=1" \
    -H "Authorization: Bearer $TOKEN" 2>&1)

log_msg "Resposta: ${RESULT:0:500}"

# 4. Parse e diagnóstico
if ! echo "$RESULT" | jq -e . >/dev/null 2>&1; then
    log_msg "ERRO: resposta não é JSON válido"
    echo "-1"
    exit 0
fi

if echo "$RESULT" | jq -e '.error' >/dev/null 2>&1; then
    ERROR_CODE=$(echo "$RESULT" | jq -r '.error.code // "?"')
    ERROR_MSG=$(echo "$RESULT" | jq -r '.error.message // "?"')
    log_msg "ERRO: $ERROR_CODE - $ERROR_MSG"
    echo "-1"
    exit 0
fi

COUNT=$(echo "$RESULT" | jq '.value | length' 2>/dev/null)

if [ -z "$COUNT" ] || [ "$COUNT" == "null" ]; then
    log_msg "Erro ao fazer parse do JSON"
    echo "-1"
elif [ "$COUNT" -gt 0 ]; then
    log_msg "✓ Encontrado: $COUNT e-mail(s)"
    echo "1"
else
    log_msg "✗ Nenhum e-mail encontrado"
    echo "0"
fi

exit 0
