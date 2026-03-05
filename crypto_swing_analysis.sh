#!/bin/bash
# crypto_swing_analysis.sh - Análise de swing trading com apresentação visual

PRICES_FILE="/home/clopes/.openclaw/workspace/crypto_prices.json"
HISTORY_DIR="/home/clopes/.openclaw/workspace/crypto_history"
REPORT_FILE="/home/clopes/.openclaw/workspace/swing_analysis.json"
REPORT_TXT="/home/clopes/.openclaw/workspace/swing_report.txt"

mkdir -p "$HISTORY_DIR"

declare -A COINS
declare -A COINGECKO_IDS
declare -A EMOJIS

COINS[BTC]="Bitcoin"
COINS[ETH]="Ethereum"
COINS[SOL]="Solana"
COINS[KAS]="Kaspa"
COINS[FLUX]="Flux"

COINGECKO_IDS[BTC]="bitcoin"
COINGECKO_IDS[ETH]="ethereum"
COINGECKO_IDS[SOL]="solana"
COINGECKO_IDS[KAS]="kaspa"
COINGECKO_IDS[FLUX]="zelcash"

EMOJIS[BTC]="₿"
EMOJIS[ETH]="Ξ"
EMOJIS[SOL]="◎"
EMOJIS[KAS]="◈"
EMOJIS[FLUX]="⚡"

CAPITAL=1000
REPORT_DATE=$(date -Iseconds)
YESTERDAY_DATE=$(date -d "yesterday" +%Y-%m-%d)

fetch_7day_data() {
    local coin=$1
    local coin_id=${COINGECKO_IDS[$coin]}
    curl -s "https://api.coingecko.com/api/v3/coins/${coin_id}/market_chart?vs_currency=usd&days=7" -H "Accept: application/json" 2>/dev/null
}

calculate_volatility() {
    local prices=$1
    echo "$prices" | jq -r '[.[] | .[1]] as $p | [range(1; ($p | length)) | ($p[.] / $p[.-1] | log)] as $returns | ($returns | add / length) as $mean | ($returns | map(. - $mean | . * .) | add / length | sqrt) * 100'
}

calculate_rsi() {
    local prices=$1
    echo "$prices" | jq -r '[.[] | .[1]] as $p | [range(1; ($p | length)) | $p[.] - $p[.-1]] as $changes | ($changes | map(select(. > 0)) | add // 0) as $gains | ($changes | map(select(. < 0) | fabs) | add // 0) as $losses | if $losses == 0 then 100 else ($gains / ($gains + $losses) * 100) end'
}

extract_yesterday_ohlc() {
    local data=$1
    local prices=$(echo "$data" | jq -r '.prices // empty')
    local yesterday_start=$(date -d "yesterday 00:00:00" +%s)000
    local yesterday_end=$(date -d "yesterday 23:59:59" +%s)999
    
    echo "$prices" | jq -r --arg start "$yesterday_start" --arg end "$yesterday_end" '
        map(select(.[0] >= ($start | tonumber) and .[0] <= ($end | tonumber))) |
        if length > 0 then {open: first | .[1], high: max_by(.[1]) | .[1], low: min_by(.[1]) | .[1], close: last | .[1]} else null end'
}

format_number() {
    local num=$1
    local decimals=$2
    printf "%.*f" "$decimals" "$num" 2>/dev/null || echo "$num"
}

# Iniciar relatório JSON
echo "{" > "$REPORT_FILE"
echo "  \"generated_at\": \"$REPORT_DATE\"," >> "$REPORT_FILE"
echo "  \"analysis_date\": \"$YESTERDAY_DATE\"," >> "$REPORT_FILE"
echo "  \"capital_per_asset\": $CAPITAL," >> "$REPORT_FILE"
echo "  \"assets\": {" >> "$REPORT_FILE"

# Iniciar relatório TXT
cat > "$REPORT_TXT" << EOF
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║           📊 ANÁLISE SWING TRADING — $YESTERDAY_DATE                    ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

💰 Capital simulado: €1.000 por ativo (€5.000 total)

📋 Estratégias comparadas:
   🎯 SWING → Comprar no mínimo do dia, vender no máximo
   📈 BUY & HOLD → Comprar na abertura, vender no fecho

═══════════════════════════════════════════════════════════════════════════════

EOF

first=true
total_swing=0
total_bh=0

for coin in BTC ETH SOL KAS FLUX; do
    echo "Analisando $coin..." >&2
    
    data=$(fetch_7day_data "$coin")
    sleep 2
    
    all_prices=$(echo "$data" | jq -r '.prices // empty')
    volatility=$(calculate_volatility "$all_prices")
    rsi=$(calculate_rsi "$all_prices")
    ohlc=$(extract_yesterday_ohlc "$data")
    
    if [ "$ohlc" != "null" ] && [ -n "$ohlc" ]; then
        open=$(echo "$ohlc" | jq -r '.open // 0')
        high=$(echo "$ohlc" | jq -r '.high // 0')
        low=$(echo "$ohlc" | jq -r '.low // 0')
        close=$(echo "$ohlc" | jq -r '.close // 0')
        
        week_high=$(echo "$all_prices" | jq -r '[.[] | .[1]] | max // 0')
        week_low=$(echo "$all_prices" | jq -r '[.[] | .[1]] | min // 0')
        
        swing_profit=$(echo "scale=2; ($CAPITAL / $low * $high) - $CAPITAL" | bc)
        swing_return=$(echo "scale=2; $swing_profit / $CAPITAL * 100" | bc)
        
        bh_profit=$(echo "scale=2; ($CAPITAL / $open * $close) - $CAPITAL" | bc)
        bh_return=$(echo "scale=2; $bh_profit / $CAPITAL * 100" | bc)
        
        advantage=$(echo "scale=2; $swing_return - $bh_return" | bc)
        
        total_swing=$(echo "scale=2; $total_swing + $swing_profit" | bc)
        total_bh=$(echo "scale=2; $total_bh + $bh_profit" | bc)
        
        range_pos=$(echo "scale=0; ($close - $week_low) / ($week_high - $week_low) * 100" | bc)
        
        # RSI status
        rsi_status="🟡 Neutro"
        if (( $(echo "$rsi > 70" | bc -l) )); then rsi_status="🔴 Sobrecomprado"; fi
        if (( $(echo "$rsi < 30" | bc -l) )); then rsi_status="🟢 Sobrevendido"; fi
        
        # JSON
        if [ "$first" = true ]; then first=false; else echo "," >> "$REPORT_FILE"; fi
        
        cat >> "$REPORT_FILE" << JSON
    "$coin": {
      "name": "${COINS[$coin]}",
      "ohlc": {"open": $open, "high": $high, "low": $low, "close": $close},
      "week_high": $week_high, "week_low": $week_low,
      "volatility": ${volatility}, "rsi": ${rsi},
      "swing": {"profit": ${swing_profit}, "return": ${swing_return}},
      "buyhold": {"profit": ${bh_profit}, "return": ${bh_return}},
      "advantage": ${advantage}
    }
JSON

        # TXT com emojis
        cat >> "$REPORT_TXT" << TXT
${EMOJIS[$coin]} ${COINS[$coin]} ($coin)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📉📈 PREÇOS DO DIA
   🕐 Abertura ........................ \$$(format_number $open 2)
   ⬆️  Máximo .......................... \$$(format_number $high 2)  🎯 venda ideal
   ⬇️  Mínimo .......................... \$$(format_number $low 2)   🛒 compra ideal
   🕕 Fecho ........................... \$$(format_number $close 2)
   📊 Amplitude ....................... $(format_number $(echo "scale=1; ($high - $low) / $low * 100" | bc) 1)%

📅 CONTEXTO SEMANAL (7 dias)
   🔺 Máximo .......................... \$$(format_number $week_high 2)
   🔻 Mínimo .......................... \$$(format_number $week_low 2)
   📍 Posição atual ................... ${range_pos}% do range

⚙️ MÉTRICAS TÉCNICAS
   📉 Volatilidade (7d) ............... $(format_number $volatility 2)%
   🌡️  RSI ............................ $(format_number $rsi 1) $rsi_status

💵 RESULTADOS — €1.000 investidos

   🎯 ESTRATÉGIA SWING
      💶 Lucro ........................ €$(format_number $swing_profit 2)
      📈 Retorno ...................... $(format_number $swing_return 2)%

   📈 ESTRATÉGIA BUY & HOLD
      💶 Lucro ........................ €$(format_number $bh_profit 2)
      📉 Retorno ...................... $(format_number $bh_return 2)%

   🏆 VANTAGEM DO SWING ............... +$(format_number $advantage 2)%

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TXT
    fi
done

# Calcular totais
avg_return_swing=$(echo "scale=2; $total_swing / 50" | bc)
avg_return_bh=$(echo "scale=2; $total_bh / 50" | bc)
advantage_total=$(echo "scale=2; $total_swing - $total_bh" | bc)

# Fechar JSON
cat >> "$REPORT_FILE" << EOF
  },
  "summary": {
    "total_swing": ${total_swing},
    "total_buyhold": ${total_bh},
    "advantage": ${advantage_total},
    "avg_return_swing": ${avg_return_swing},
    "avg_return_buyhold": ${avg_return_bh}
  }
}
EOF

# Resumo final no TXT
cat >> "$REPORT_TXT" << EOF
╔══════════════════════════════════════════════════════════════════════════════╗
║                         📊 RESUMO DO PORTFÓLIO 📊                            ║
╚══════════════════════════════════════════════════════════════════════════════╝

💼 Total investido .......................... €5.000

🎯 LUCRO TOTAL — ESTRATÉGIA SWING
   💶 Montante ............................. €$(format_number $total_swing 2)
   📈 Retorno médio ........................ $(format_number $avg_return_swing 2)%

📈 LUCRO TOTAL — BUY & HOLD
   💶 Montante ............................. €$(format_number $total_bh 2)
   📉 Retorno médio ........................ $(format_number $avg_return_bh 2)%

🏆 VANTAGEM ABSOLUTA DO SWING
   💎 Diferença ............................ €$(format_number $advantage_total 2)
   🚀 Superioridade ........................ $(format_number $(echo "scale=0; ($total_swing - $total_bh) / $total_bh * 100" | bc) 0)%

═══════════════════════════════════════════════════════════════════════════════

💡 NOTA IMPORTANTE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  Estes resultados assumem timing PERFEITO (comprar exatamente no mínimo e
    vender exatamente no máximo). 

🎯 Na prática, um trader experiente captura 30-50% deste movimento.

✅ Mesmo assim, a estratégia de swing trading tende a superar o buy & hold
   em mercados voláteis.

═══════════════════════════════════════════════════════════════════════════════

🕐 Gerado em: $REPORT_DATE
🔌 Fonte: CoinGecko API | Dados de 7 dias

═══════════════════════════════════════════════════════════════════════════════
EOF

echo "✅ Análise completa:"
echo "   JSON: $REPORT_FILE"
echo "   TXT:  $REPORT_TXT"
