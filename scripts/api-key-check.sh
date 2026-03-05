#!/bin/bash
# api-key-check.sh - Verificação diária de API keys

REPORT_FILE="/home/clopes/.openclaw/workspace/memory/api-key-check-$(date +%Y%m%d).json"
LOG_FILE="/home/clopes/.openclaw/workspace/memory/api-key-check-$(date +%Y%m%d).log"
TIMESTAMP=$(date -Iseconds)

echo "=== API Key Check - $TIMESTAMP ===" > "$LOG_FILE"

# Iniciar relatório JSON
echo "{\"timestamp\": \"$TIMESTAMP\", \"keys\": [], \"summary\": {}}" > "$REPORT_FILE"

# Verificar Moonshot API Key
echo "Checking Moonshot API..." >> "$LOG_FILE"

# Tentar uma chamada simples à API da Moonshot para verificar validade
MOONSHOT_RESPONSE=$(curl -s -w "\n%{http_code}" https://api.moonshot.ai/v1/models \
  -H "Authorization: Bearer $(cat ~/.config/openclaw/moonshot.env 2>/dev/null | grep API_KEY | cut -d= -f2 || echo '')" \
  -H "Content-Type: application/json" 2>/dev/null || echo "ERROR")

HTTP_CODE=$(echo "$MOONSHOT_RESPONSE" | tail -1)
BODY=$(echo "$MOONSHOT_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    MOONSHOT_STATUS="valid"
    MODELS=$(echo "$BODY" | jq -r '.data | length' 2>/dev/null || echo "0")
else
    MOONSHOT_STATUS="invalid_or_error"
    MODELS="0"
fi

# Adicionar ao relatório
jq --arg status "$MOONSHOT_STATUS" \
   --arg models "$MODELS" \
   --arg code "$HTTP_CODE" \
   '.keys += [{"provider": "moonshot", "status": $status, "models_available": $models, "http_code": $code}]' \
   "$REPORT_FILE" > /tmp/api-check-tmp.json && mv /tmp/api-check-tmp.json "$REPORT_FILE"

# Verificar outras APIs configuradas
# (Adicionar mais conforme necessário)

# Calcular summary
TOTAL_KEYS=$(jq '.keys | length' "$REPORT_FILE")
VALID_KEYS=$(jq '[.keys[] | select(.status == "valid")] | length' "$REPORT_FILE")
INVALID_KEYS=$(jq '[.keys[] | select(.status != "valid")] | length' "$REPORT_FILE")

jq --arg total "$TOTAL_KEYS" \
   --arg valid "$VALID_KEYS" \
   --arg invalid "$INVALID_KEYS" \
   '.summary = {"total_keys": ($total | tonumber), "valid": ($valid | tonumber), "invalid": ($invalid | tonumber)}' \
   "$REPORT_FILE" > /tmp/api-check-tmp.json && mv /tmp/api-check-tmp.json "$REPORT_FILE"

echo "✅ API key check complete. Valid: $VALID_KEYS, Invalid: $INVALID_KEYS" >> "$LOG_FILE"
echo "Report: $REPORT_FILE"
