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