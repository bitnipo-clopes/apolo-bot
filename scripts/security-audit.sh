#!/bin/bash
# security-audit.sh - Auditoria de segurança diária

set -e

REPORT_FILE="/home/clopes/.openclaw/workspace/memory/security-audit-$(date +%Y%m%d).json"
TIMESTAMP=$(date -Iseconds)
HOSTNAME=$(hostname)

echo "{\"timestamp\": \"$TIMESTAMP\", \"hostname\": \"$HOSTNAME\", \"checks\": {" > "$REPORT_FILE"

# 1. OpenClaw Security Audit
echo "  \"openclaw_audit\": " >> "$REPORT_FILE"
openclaw security audit --json 2>/dev/null >> "$REPORT_FILE" || echo "{\"error\": \"audit failed\"}" >> "$REPORT_FILE"
echo "," >> "$REPORT_FILE"

# 2. Gateway Status
echo "  \"gateway_status\": " >> "$REPORT_FILE"
openclaw status --json 2>/dev/null | jq '{gateway: .gateway, status: .overview}' >> "$REPORT_FILE" || echo "{\"error\": \"status failed\"}" >> "$REPORT_FILE"
echo "," >> "$REPORT_FILE"

# 3. Listening Ports
echo "  \"listening_ports\": " >> "$REPORT_FILE"
ss -ltnup --json 2>/dev/null | jq '[.[] | {port: .local_port, process: .process, state: .state}]' >> "$REPORT_FILE" || echo "[]" >> "$REPORT_FILE"
echo "," >> "$REPORT_FILE"

# 4. Firewall Status
echo "  \"firewall\": " >> "$REPORT_FILE"
UFW_STATUS=$(sudo ufw status 2>/dev/null || echo "inactive")
if echo "$UFW_STATUS" | grep -q "Status: active"; then
    echo "{\"status\": \"active\", \"rules\": \"$(echo "$UFW_STATUS" | grep -c ALLOW)\"}" >> "$REPORT_FILE"
else
    echo "{\"status\": \"inactive\"}" >> "$REPORT_FILE"
fi
echo "," >> "$REPORT_FILE"

# 5. SSH Config
echo "  \"ssh\": " >> "$REPORT_FILE"
if [ -f /etc/ssh/sshd_config ]; then
    SSH_ROOT=$(grep -E "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}' || echo "not_set")
    SSH_PASS=$(grep -E "^PasswordAuthentication" /etc/ssh/sshd_config | awk '{print $2}' || echo "not_set")
    SSH_PORT=$(grep -E "^Port" /etc/ssh/sshd_config | awk '{print $2}' || echo "22")
    echo "{\"permit_root\": \"$SSH_ROOT\", \"password_auth\": \"$SSH_PASS\", \"port\": \"$SSH_PORT\"}" >> "$REPORT_FILE"
else
    echo "{\"error\": \"sshd_config not found\"}" >> "$REPORT_FILE"
fi
echo "," >> "$REPORT_FILE"

# 6. Exposed Services (non-localhost)
echo "  \"exposed_services\": " >> "$REPORT_FILE"
ss -ltnup 2>/dev/null | grep -v "127.0.0.1" | grep -v "::1" | awk 'NR>1 {print $4}' | jq -R -s -c 'split("\n") | map(select(length > 0))' >> "$REPORT_FILE" || echo "[]" >> "$REPORT_FILE"

echo "}}" >> "$REPORT_FILE"

echo "✅ Security audit complete: $REPORT_FILE"
