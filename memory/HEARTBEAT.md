# HEARTBEAT.md

Este ficheiro documenta as rotinas automatizadas e o estado de saúde do Apolo.

## Rotinas de Backup

- **Backup Diário do Workspace para o GitHub:** `cd /home/clopes/.picoclaw/workspace && git add . && git commit -m "Rotina diária de backup do workspace para o GitHub" && git push origin main`
  - **Frequência:** Diariamente às 04:00
  - **ID da Tarefa Cron:** `58ceb939f27d5cc1`

- **Backup Diário do Workspace para a Pen USB:** `cp -r /home/clopes/.picoclaw/workspace /mnt/storage/picoclaw-backup`
  - **Frequência:** Diariamente às 04:05
  - **ID da Tarefa Cron:** `5b18d62bb11cbfd1`

## Estado de Saúde

- Última Verificação: 2026-02-26 13:26:10 (Quinta-feira)
- **Status:** Operacional. O problema de permissão no backup diário para a Pen USB parece estar resolvido. Teste manual de cópia de ficheiros foi bem-sucedido. É recomendável monitorizar o próximo backup agendado.
