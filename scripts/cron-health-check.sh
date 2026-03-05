#!/bin/bash
# cron-health-check.sh - Verificação diária de saúde dos cron jobs

REPORT_FILE="/home/clopes/.openclaw/workspace/memory/cron-health-$(date +%Y%m%d).json"
LOG_FILE="/home/clopes/.openclaw/workspace/memory/cron-health-$(date +%Y%m%d).log"
TIMESTAMP=$(date -Iseconds)

echo "=== Cron Health Check - $TIMESTAMP ===" > "$LOG_FILE"

# Lista de crons esperados (nomes que devem existir)
EXPECTED_CRONS=(
    "crypto-monitor-30min"
    "security-audit-7am"
    "security-fix-730am"
    "api-key-check-8am"
    "crypto-morning-report"
    "crypto-evening-report"
    "openclaw-backup-2h"
    "weekly-context-audit"
)

# Obter lista atual de crons
echo "Fetching current cron jobs..." >> "$LOG_FILE"
openclaw cron list --json > /tmp/current-crons.json 2>> "$LOG_FILE" || echo "[]" > /tmp/current-crons.json

# Iniciar relatório
cat > "$REPORT_FILE" << EOF
{
  "timestamp": "$TIMESTAMP",
  "expected_count": ${#EXPECTED_CRONS[@]},
  "actual_count": 0,
  "checks": [],
  "missing": [],
  "failed": [],
  "restarted": [],
  "summary": {}
}
EOF

# Verificar cada cron esperado
for cron_name in "${EXPECTED_CRONS[@]}"; do
    echo "Checking: $cron_name" >> "$LOG_FILE"
    
    # Procurar o cron na lista atual
    CRON_INFO=$(jq -r --arg name "$cron_name" '.[] | select(.name == $name)' /tmp/current-crons.json)
    
    if [ -z "$CRON_INFO" ]; then
        echo "  ❌ MISSING: $cron_name" >> "$LOG_FILE"
        jq --arg name "$cron_name" '.missing += [$name]' "$REPORT_FILE" > /tmp/cron-health-tmp.json && mv /tmp/cron-health-tmp.json "$REPORT_FILE"
    else
        CRON_ID=$(echo "$CRON_INFO" | jq -r '.id // "unknown"')
        CRON_STATUS=$(echo "$CRON_INFO" | jq -r '.state.lastRunStatus // "unknown"')
        CRON_ENABLED=$(echo "$CRON_INFO" | jq -r '.enabled // false')
        LAST_RUN=$(echo "$CRON_INFO" | jq -r '.state.lastRunAtMs // 0')
        
        # Verificar se falhou
        if [ "$CRON_STATUS" = "error" ] || [ "$CRON_STATUS" = "failed" ]; then
            echo "  ❌ FAILED: $cron_name (status: $CRON_STATUS)" >> "$LOG_FILE"
            jq --arg name "$cron_name" --arg id "$CRON_ID" '.failed += [{"name": $name, "id": $id, "status": "failed"}]' "$REPORT_FILE" > /tmp/cron-health-tmp.json && mv /tmp/cron-health-tmp.json "$REPORT_FILE"
        elif [ "$CRON_ENABLED" = "false" ]; then
            echo "  ⚠️ DISABLED: $cron_name" >> "$LOG_FILE"
            jq --arg name "$cron_name" '.checks += [{"name": $name, "status": "disabled", "action": "needs_enable"}]' "$REPORT_FILE" > /tmp/cron-health-tmp.json && mv /tmp/cron-health-tmp.json "$REPORT_FILE"
        else
            echo "  ✅ OK: $cron_name" >> "$LOG_FILE"
            jq --arg name "$cron_name" '.checks += [{"name": $name, "status": "ok"}]' "$REPORT_FILE" > /tmp/cron-health-tmp.json && mv /tmp/cron-health-tmp.json "$REPORT_FILE"
        fi
    fi
done

# Calcular summary
ACTUAL_COUNT=$(jq '.checks | length' "$REPORT_FILE")
MISSING_COUNT=$(jq '.missing | length' "$REPORT_FILE")
FAILED_COUNT=$(jq '.failed | length' "$REPORT_FILE")
OK_COUNT=$(jq '[.checks[] | select(.status == "ok")] | length' "$REPORT_FILE")

jq --arg actual "$ACTUAL_COUNT" \
   --arg missing "$MISSING_COUNT" \
   --arg failed "$FAILED_COUNT" \
   --arg ok "$OK_COUNT" \
   '.actual_count = ($actual | tonumber) | .summary = {"total_expected": .expected_count, "found": ($actual | tonumber), "missing": ($missing | tonumber), "failed": ($failed | tonumber), "ok": ($ok | tonumber)}' \
   "$REPORT_FILE" > /tmp/cron-health-tmp.json && mv /tmp/cron-health-tmp.json "$REPORT_FILE"

echo "✅ Cron health check complete. OK: $OK_COUNT, Failed: $FAILED_COUNT, Missing: $MISSING_COUNT" >> "$LOG_FILE"
echo "Report: $REPORT_FILE"
