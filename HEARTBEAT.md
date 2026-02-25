# HEARTBEAT.md

Este ficheiro documenta as rotinas automatizadas e o estado de saúde do Apolo.

## Rotinas de Backup

- **Backup Diário do Workspace para o GitHub:** `cd /home/clopes/.picoclaw/workspace && git add . && git commit -m "Rotina diária de backup do workspace para o GitHub" && git push origin main`
  - **Frequência:** Diariamente às 04:00
  - **ID da Tarefa Cron:** `58ceb939f27d5cc1`

- **Backup Diário do Workspace para a Pen USB:** `cp -r /home/clopes/.picoclaw/workspace /mnt/storage/picoclaw-backup`
  - **Frequência:** Diariamente às 04:05
  - **ID da Tarefa Cron:** `5b18d62bb11cbfd1`
  - **Estado:** Falhou devido a permissões de escrita em `/mnt/storage/picoclaw-backup` (tentativa de correção falhou devido a autenticação sudo)

## Estado de Saúde

- **Última Verificação:** 2026-02-25 05:26:10 (Quarta-feira)
- **Status:** Operacional com problemas de permissão no backup USB
