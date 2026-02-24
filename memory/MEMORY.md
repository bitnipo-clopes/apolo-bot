# Long-term Memory

This file stores important information that should persist across sessions.

## User Information

(Important facts about user)

## Preferences

(User preferences learned over time)

## Important Notes

### Gestão da Memória e Contexto do Apolo

- **Memória de Contexto (Curto Prazo):**
  - Limitada por tokens. Quando o limite é atingido, a mensagem "⚠️ Memory threshold reached. Optimizing conversation history..." é exibida.
  - A otimização envolve resumir ou descartar partes mais antigas da conversa para abrir espaço para novas informações.
  - Este processo é automático e serve para manter a fluidez da conversa; não grava automaticamente a conversa completa em `MEMORY.md`.

- **`MEMORY.md` (Longo Prazo):**
  - Ficheiro dedicado à persistência de informações cruciais entre sessões.
  - Apolo escreve para este ficheiro explicitamente, usando `write_file` ou `append_file`, para guardar factos importantes, preferências do utilizador, rotinas agendadas, etc.
  - Não é um registo automático ou completo de todas as interações da conversa.
  - Para garantir que uma informação é lembrada a longo prazo, o utilizador deve pedir explicitamente para Apolo a adicionar ao `MEMORY.md`.

(Things to remember)

## Configuration

- Model preferences
- Channel settings
- Skills enabled

## Rotinas de Backup

- **Backup Diário do Workspace para o GitHub:** `cd /home/clopes/.picoclaw/workspace && git add . && git commit -m "Rotina diária de backup do workspace para o GitHub" && git push origin main`
  - **Frequência:** Diariamente às 04:00
  - **ID da Tarefa Cron:** `58ceb939f27d5cc1`

- **Backup Diário do Workspace para a Pen USB:** `cp -r /home/clopes/.picoclaw/workspace /mnt/storage/picoclaw-backup`
  - **Frequência:** Diariamente às 04:05
  - **ID da Tarefa Cron:** `5b18d62bb11cbfd1`

## Estado de Saúde

- **Última Verificação:** 2026-02-23 22:26 (Segunda-feira)
- **Status:** Operacional
- **Observações:** Todas as rotinas agendadas estão ativas e a funcionar como esperado.
