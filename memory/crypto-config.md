# Crypto Configuration

## Moedas Monitorizadas

| Moeda | Tipo | CoinGecko ID | Binance |
|-------|------|--------------|---------|
| BTC | Reserva de valor | bitcoin | BTCUSDT |
| ETH | DeFi/smart contracts | ethereum | ETHUSDT |
| SOL | Alta performance | solana | SOLUSDT |
| KAS | PoW BlockDAG | kaspa | — |
| FLUX | Infraestrutura descentralizada | zelcash | FLUXUSDT |

## Cron Jobs

| Job | Schedule | Função |
|-----|----------|--------|
| crypto-monitor-30min | A cada 30min | Verificar preços, alertar se >5% |
| crypto-morning-report | 08:00 Lisboa | Relatório matinal completo |
| crypto-evening-report | 20:00 Lisboa | Resumo diário |

### Horário de Silêncio
- **21:00 - 08:00 Lisboa**: Não enviar mensagens para Telegram
- Durante este período: apenas registar dados localmente

## Análise Swing Trading

- **Objetivo:** Simular lucro comprando nos mínimos, vendendo nos máximos do dia anterior
- **Capital:** €1.000 por ativo (€5.000 total)
- **Script:** `crypto_swing_analysis.sh`
- **Output:** `swing_analysis.json`
- **Incluir em:** Relatório matinal (08:00)

## Ficheiros do Sistema

| Ficheiro | Descrição |
|----------|-----------|
| `crypto_prices.json` | Preços base/previous/current |
| `crypto_swing_analysis.sh` | Script de análise swing |
| `swing_analysis.json` | Dados estruturados swing |
| `crypto_history/` | Dados históricos OHLC |

## Preferências do Carlos

- Perfil: Iniciante, risco conservador
- Capital: 500-2000€
- Abordagem: DCA, compras em quedas, nunca all-in

## Notas

- Base prices: 2026-03-01
- FLUX teve erro de dados em 2026-03-02 (0.022$ vs 0.060$) — validação adicionada
