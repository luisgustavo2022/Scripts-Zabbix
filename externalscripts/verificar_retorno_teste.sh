#!/bin/bash

# Variáveis
SERVIDOR=""
COMPARTILHAMENTO="pdf"
USUARIO=""
WORKGROUP=""
SENHA=""  # SENHA CORRETA
DATA_HOJE=$(date "+%b %e")

case "$1" in
    bradesco)
        PADRAO="CB0*.RET"
        ;;
    grafeno)
        PADRAO="Nf_charge*.ret*"
        ;;
    *)
        echo "0"
        exit 1
        ;;
esac

# Busca arquivos
LISTA=$(smbclient //${SERVIDOR}/${COMPARTILHAMENTO} -U "$USUARIO" -W "$WORKGROUP" --password="$SENHA" -c "ls $PADRAO" 2>/dev/null)

# Verifica se algum arquivo contém a data de hoje
if echo "$LISTA" | grep -q "$DATA_HOJE"; then
    echo 1
else
    echo 0
fi
