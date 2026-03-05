# Relatório de Correção de Segurança - 2026-03-05 07:30

## ✅ CORRIGIDO

### 1. [CRÍTICO] Modelo pequeno sem sandboxing
**Problema:** O modelo llama/heretic-35b (35B parâmetros) estava configurado sem sandboxing e com acesso a ferramentas web (web_fetch, browser).

**Correção aplicada:**
- Ficheiro: `~/.openclaw/openclaw.json`
- Adicionada configuração `agents.defaults.sandbox.mode: "all"`
- Adicionada secção `tools.deny: ["web_search", "web_fetch", "browser"]`

**Comandos usados:**
```bash
# Edição direta do ficheiro de configuração
# Adicionado sandbox.mode: "all" em agents.defaults
# Adicionado tools.deny com web_search, web_fetch, browser
```

**Confirmação:**
```json
"sandbox": {
  "mode": "all"
},
"tools": {
  "deny": ["web_search", "web_fetch", "browser"]
}
```

---

## 📋 PENDENTE (MEDIUM/LOW) - Aguardando aprovação

### 1. [MEDIUM] Firewall UFW - Necessita configuração manual
**Estado atual:**
- UFW está instalado e o serviço está ativo
- Não foi possível verificar/configurar regras (sem acesso sudo)
- Porta 22 (SSH) aberta em 0.0.0.0
- Porta 18789 (OpenClaw Gateway) apenas em 127.0.0.1 ✅

**Risco:** Sem regras de firewall explícitas, o sistema depende apenas das configurações default do sistema.

**Sugestão de correção:**
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow from 192.168.1.0/24 to any port 18789 comment 'OpenClaw LAN only'
sudo ufw enable
```

### 2. [LOW] gateway.trustedProxies vazio
**Risco:** Se expuseres o Control UI através de um reverse proxy, headers podem ser spoofed.

**Sugestão:** Configurar `gateway.trustedProxies` com os IPs do teu proxy, ou manter o Control UI apenas local (loopback).

### 3. [LOW] denyCommands com entradas ineficazes
**Risco:** Os comandos listados (camera.snap, calendar.add, etc.) não são comandos válidos do sistema - o denyCommands usa matching exato de nomes de comandos.

**Sugestão:** Revisar a lista e usar nomes de comandos exatos (ex: canvas.present, canvas.snapshot).

---

## 🔒 POSTURA DE SEGURANÇA ATUAL

| Componente | Estado | Notas |
|------------|--------|-------|
| OpenClaw Gateway | ✅ Seguro | Bind em loopback (127.0.0.1), autenticação por token |
| Modelos pequenos | ✅ Corrigido | Sandboxing ativado, ferramentas web bloqueadas |
| SSH | ⚠️ Não verificado | Sem acesso para verificar configuração |
| Firewall | ⚠️ Parcial | Serviço ativo, regras não confirmadas |
| Root login | ❓ Desconhecido | Não foi possível verificar sshd_config |

---

## PRÓXIMOS PASSOS RECOMENDADOS

1. **Configurar UFW manualmente** com as regras sugeridas acima
2. **Verificar configuração SSH:**
   ```bash
   sudo grep -E '^(PermitRootLogin|PasswordAuthentication|Port)' /etc/ssh/sshd_config
   ```
3. **Rever denyCommands** no openclaw.json
4. **Configurar trustedProxies** se usares reverse proxy

---

*Relatório gerado automaticamente em 2026-03-05 07:35*
