#!/bin/bash
# /usr/lib/zabbix/externalscripts/consulta_saldo_grafeno.sh

CREDFILE="/etc/zabbix/grafeno_creds"

# carrega variáveis sem expor em histórico
[ -r "$CREDFILE" ] || { echo "0"; exit 1; }
. "$CREDFILE"

# query que evita NULL
SQL="SET NOCOUNT ON; SELECT ISNULL(SUM(saldoconta),0) FROM nfBankAccountsGrafeno WHERE saldoconta > 0;"

# executa e limpa saída para retornar apenas o valor
echo "$SQL" | isql "$DSN" "$USER" "$PASS" -b 2>/dev/null | \
sed -n '/|/s/|//gp' |       # remove bordas da tabela
sed 's/^[ \t]*//;s/[ \t]*$//' |  # remove espaços no início/fim
grep -E '^[0-9]' | head -n1    # pega a primeira linha numérica
