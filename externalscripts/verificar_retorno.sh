#!/bin/bash

SERVIDOR=""
COMPARTILHAMENTO=""
USUARIO=""
WORKGROUP=""
SENHA=""
DATA_HOJE=$(date "+%b %e" | tr -s ' ')

case "$1" in
    bradesco)
        PADRAO="COB_237_*.txt"
        ;;
    grafeno)
        PADRAO="Nf_charge*.ret*"
        ;;
    *)
        echo "0"
        exit 1
        ;;
esac

LISTA=$(smbclient //${SERVIDOR}/${COMPARTILHAMENTO} -U "$USUARIO" -W "$WORKGROUP" --password="$SENHA" -c "ls $PADRAO" 2>/dev/null)

if echo "$LISTA" | grep -q "$DATA_HOJE"; then
    echo 1
else
    echo 0
fi
