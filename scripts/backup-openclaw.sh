#!/bin/bash
# backup-openclaw.sh - Backup completo do workspace OpenClaw para GitHub

set -e

REPO_URL="git@github.com:bitnipo-clopes/apolo-bot.git"
WORKSPACE_DIR="/home/clopes/.openclaw/workspace"
SKILLS_DIR="/home/clopes/.openclaw/skills"
CONFIG_DIR="/home/clopes/.openclaw"
BACKUP_DIR="/tmp/openclaw-backup-$(date +%Y%m%d-%H%M%S)"
TIMESTAMP=$(date -Iseconds)

echo "=== OpenClaw Backup - $TIMESTAMP ==="

# Criar diretório temporário
mkdir -p "$BACKUP_DIR"

# Clonar repositório
if [ -d "$WORKSPACE_DIR/.git" ]; then
    cd "$WORKSPACE_DIR"
    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
else
    git clone "$REPO_URL" "$BACKUP_DIR/repo"
    cd "$BACKUP_DIR/repo"
fi

# Garantir que .openclaw e skills estão no .gitignore se necessário
if ! grep -q "^\.openclaw/" .gitignore 2>/dev/null; then
    echo ".openclaw/" >> .gitignore
fi

# Adicionar todos os ficheiros do workspace
git add -A

# Verificar se há alterações
if git diff --cached --quiet; then
    echo "Nenhuma alteração para commit."
    exit 0
fi

# Commit com timestamp
git commit -m "Backup automático - $TIMESTAMP" -m "- Workspace files" -m "- Skills" -m "- Memory" -m "- Config"

# Push
git push origin HEAD

echo "✅ Backup concluído: $TIMESTAMP"
echo "📁 Repo: $REPO_URL"

# Limpar
rm -rf "$BACKUP_DIR"
