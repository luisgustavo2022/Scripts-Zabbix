#!/bin/bash

SERVIDOR=""
COMPARTILHAMENTO="arqsbco"
USUARIO=""
WORKGROUP=""
SENHA=""
DATA_HOJE=$(LC_ALL=C date "+%b %e" | tr -s ' ')

LISTA=$(smbclient //${SERVIDOR}/${COMPARTILHAMENTO} \
  -U "$USUARIO" -W "$WORKGROUP" --password="$SENHA" \
  -c "ls Nf_charge*.ret*" 2>/dev/null)

QUANTIDADE=$(echo "$LISTA" | grep -v "^$" | grep "$DATA_HOJE" | grep -v "blocks" | wc -l | tr -d ' ')


if [ "$QUANTIDADE" -lt 20 ]; then
    echo 0  # menos de 20 arquivos
else
    echo 1  # 10 ou mais arquivos
fi
