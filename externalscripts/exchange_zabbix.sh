#!/bin/bash

TENANT_ID=""
CLIENT_ID=""
CLIENT_SECRET=""
ZABBIX_SERVER="127.0.0.1"
ZABBIX_HOST="Exchange365"
TMP_FILE="/tmp/zabbix_exchange_payload.txt"
ZABBIX_SENDER_BIN=$(which zabbix_sender || echo "/usr/bin/zabbix_sender")

# 1. Autenticação na API da Microsoft
TOKEN_RESPONSE=$(curl -s -X POST "https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/token" \
    -d "client_id=$CLIENT_ID" \
    -d "scope=https%3A%2F%2Fgraph.microsoft.com%2F.default" \
    -d "client_secret=$CLIENT_SECRET" \
    -d "grant_type=client_credentials")

TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
    echo "Erro na autenticação com a Microsoft."
    exit 1
fi

# 2. Baixar o relatório
CSV_DATA=$(curl -s -L -H "Authorization: Bearer $TOKEN" \
    "https://graph.microsoft.com/v1.0/reports/getMailboxUsageDetail(period='D7')")

> "$TMP_FILE"
LLD_JSON='{"data":['
SENDER_CONTENT=""
FIRST_LINE=1

# 3. Processamento linha a linha
while IFS= read -r line; do
    line=$(echo "$line" | tr -d '\r')
    
    if [ $FIRST_LINE -eq 1 ]; then
        FIRST_LINE=0
        continue
    fi
    
    if [ -z "$line" ]; then
        continue
    fi

    UPN=$(echo "$line" | awk -F',' '{print $2}' | tr -d '"')
    STORAGE=$(echo "$line" | awk -F',' '{print $9}' | tr -d '"')

    if [[ "$UPN" =~ @ ]] && [[ "$STORAGE" =~ ^[0-9]+$ ]]; then
        LLD_JSON+='{"{#MAILBOX}":"'$UPN'","{#NOME}":"'$UPN'","{#TAMANHO}":"'$STORAGE'"},'
        SENDER_CONTENT+="$ZABBIX_HOST exchange.mailbox.size[$UPN] $STORAGE\n"
    fi
done <<< "$CSV_DATA"

LLD_JSON=$(echo "$LLD_JSON" | sed 's/,$//')
LLD_JSON+=']}'

# 4. Grava o payload limpo
echo "$ZABBIX_HOST exchange.discovery $LLD_JSON" > "$TMP_FILE"
if [ ! -z "$SENDER_CONTENT" ]; then
    echo -e "$SENDER_CONTENT" >> "$TMP_FILE"
fi

# 5. Envia para o Zabbix
$ZABBIX_SENDER_BIN -z "$ZABBIX_SERVER" -i "$TMP_FILE"
rm -f "$TMP_FILE"
