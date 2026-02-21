#!/bin/bash
# Backup do Workspace Clawd e Configurações para a Pen
# Destino: /mnt/storage/backups

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEST="/mnt/storage/backups/$TIMESTAMP"

mkdir -p "$DEST"

echo "A iniciar backup em $TIMESTAMP..."

# Backup do Workspace (Clawd)
cp -r /home/clopes/clawd "$DEST/workspace_clawd"

# Backup das Configurações (.openclaw)
mkdir -p "$DEST/config"
cp /home/clopes/.openclaw/*.json "$DEST/config/"

# Limpar backups com mais de 7 dias para não encher a pen
find /mnt/storage/backups/* -type d -ctime +7 -exec rm -rf {} +

echo "Backup concluído com sucesso em $DEST"
