---
name: saude-total
description: Gestão proativa do protocolo de longevidade do Carlos. Use para: (1) Registar logs de clareza mental e sintomas, (2) Validar o timing de suplementos e binders (pós-sauna), (3) Consultar o perfil biológico consolidado para cruzar novos dados ou biohacks, (4) Gerar o relatório integrado de saúde, finanças e tecnologia. Triggers: "estou a sentir-me...", "vou fazer sauna", "relatório integrado", "como está o meu perfil".
---

# Saúde Total ⚡

Este skill operacionaliza o plano de longevidade de 100 anos do Carlos, focando na recuperação da memória de trabalho e na desintoxicação de metais pesados.

## Fluxos Principais

### 1. Protocolo de Desintoxicação (Sauna & Binders)
Sempre que o Carlos mencionar que vai fazer ou fez sauna:
- **Validar Niacina:** Perguntar se tomou Niacina pura (Flush) 30 min antes.
- **Validar Banho Frio:** Confirmar o choque térmico imediato.
- **Timing do Carvão:** Instruir a toma de **Carvão Ativado** logo após o banho, com muita água.
- **Janela de Suplementos:** Lembrar que deve esperar **2 horas** após o carvão para tomar qualquer outro suplemento.

### 2. Log de Clareza Mental e Memória
Diariamente ou quando solicitado:
- Registar a escala de 0 a 10 de clareza mental.
- Comparar com os dias anteriores (ver `memory/`).
- Se a clareza for < 5, sugerir aumento imediato de **Magnésio Treonato** ou dose extra de **C8 (Keto Octane)**.

### 3. Consulta ao Perfil Biológico
Ao analisar novos exames ou sintomas, ler obrigatoriamente:
- `bio_perfil_carlos.txt`: Contém os SNPs críticos (MTHFR, COMT, GST) e o histórico de metais (Alumínio/Mercúrio).
- `suplementos.txt`: Lista atualizada para evitar interações.

### 4. Relatório Integrado Zeus ⚡
Ao comando "relatório integrado", gerar um resumo em 3 frentes:
1. **Saúde:** Estado da desintoxicação e sugestão de dose de foco.
2. **Finanças:** Preço de BTC/EUR e métricas de mercado (MVRV, etc.).
3. **Tech:** Novidades de IA aplicadas à automação ou longevidade.

## Diretrizes de Resposta
- **Não usar medicina clássica:** Ignorar valores de referência de laboratório. Focar em níveis de otimização funcional.
- **Rigor Científico:** Priorizar referências da PubMed e dos mentores (O'Mara, Duarte, Asprey, Myhill, Bright).
- **Proatividade:** Se for detectado um comportamento fora do protocolo (ex: esquecer o binder), alertar imediatamente.
