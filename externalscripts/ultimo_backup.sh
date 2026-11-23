#!/bin/bash

# Variáveis de conexão SMB
SERVIDOR=""
COMPARTILHAMENTO="d$"
PASTA="Backup"
USUARIO=""
SENHA="!"

# Executa o smbclient e captura a listagem
LISTA=$(smbclient //${SERVIDOR}/${COMPARTILHAMENTO} "$SENHA" -U "$USUARIO" -c "cd $PASTA; ls")

# Filtra apenas linhas com arquivos, ignorando diretórios "." e ".."
ARQUIVOS=$(echo "$LISTA" | grep -vE '^\s*\.\.?(\s|$)')

# Se não houver arquivos, retorna erro
if [ -z "$ARQUIVOS" ]; then
    echo 0
    exit 1
fi

# Extrai e ordena datas válidas
ULTIMO_BACKUP=$(echo "$ARQUIVOS" | awk 'NF >= 4 {printf "%s %s %s %s\n", $(NF-3), $(NF-2), $(NF-1), $NF}' | sort | tail -n 1)

# Converte a data para timestamp
TIMESTAMP=$(date -d "$ULTIMO_BACKUP" +%s 2>/dev/null)

# Se a conversão falhar, retorna 0
if [[ -z "$TIMESTAMP" ]]; then
    echo 0
    exit 1
fi

# Exibe o timestamp
echo "$TIMESTAMP"

