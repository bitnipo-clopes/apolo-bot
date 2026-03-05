#!/bin/bash
# crypto_swing_analysis.sh - Análise de swing trading para relatórios crypto
# Simula compras nos mínimos e vendas nos máximos do dia anterior

PRICES_FILE="/home/clopes/.openclaw/workspace/crypto_prices.json"
HISTORY_DIR="/home/clopes/.openclaw/workspace/crypto_history"
REPORT_FILE="/home/clopes/.openclaw/workspace/swing_analysis.json"

# Criar diretório de histórico se não existir
mkdir -p "$HISTORY_DIR"

# Configuração dos ativos
declare -A COINS
declare -A COINGECKO_IDS
COINS[BTC]="Bitcoin"
COINS[ETH]="Ethereum"
COINS[SOL]="Solana"
COINS[KAS]="Kaspa"
COINS[FLUX]="Flux"

COINGECKO_IDS[BTC]="bitcoin"
COINGECKO_IDS[ETH]="ethereum"
COINGECKO_IDS[SOL]="solana"
COINGECKO_IDS[KAS]="kaspa"
COINGECKO_IDS[FLUX]="zelcash"  # CoinGecko usa "zelcash" para FLUX

# Data de ontem (formato Unix timestamp)
YESTERDAY=$(date -d "yesterday" +%s)
TODAY=$(date +%s)

# Função para buscar dados OHLC de um ativo
fetch_ohlc() {
    local coin=$1
    local coin_id=${COINGECKO_IDS[$coin]}
    local history_file="$HISTORY_DIR/${coin}_daily.json"
    
    # Buscar dados de mercado dos últimos 2 dias (inclui ontem completo)
    # CoinGecko API: /coins/{id}/market_chart?vs_currency=usd&days=2
    local response=$(curl -s "https://api.coingecko.com/api/v3/coins/${coin_id}/market_chart?vs_currency=usd&days=2" \
        -H "Accept: application/json" 2>/dev/null)
    
    if [ -z "$response" ] || echo "$response" | grep -q "error"; then
        echo "null"
        return
    fi
    
    # Guardar resposta
    echo "$response" > "$history_file"
    echo "$response"
}

# Função para extrair OHLC do dia anterior a partir dos dados de preços
extract_yesterday_ohlc() {
    local data=$1
    
    if [ "$data" = "null" ] || [ -z "$data" ]; then
        echo "null"
        return
    fi
    
    # Extrair preços (array de [timestamp, price])
    local prices=$(echo "$data" | jq -r '.prices // empty')
    
    if [ -z "$prices" ] || [ "$prices" = "null" ]; then
        echo "null"
        return
    fi
    
    # Calcular início e fim do dia anterior (00:00 a 23:59)
    local yesterday_start=$(date -d "yesterday 00:00:00" +%s)000
    local yesterday_end=$(date -d "yesterday 23:59:59" +%s)999
    
    # Filtrar preços do dia anterior e calcular OHLC
    local ohlc=$(echo "$prices" | jq -r --arg start "$yesterday_start" --arg end "$yesterday_end" '
        map(select(.[0] >= ($start | tonumber) and .[0] <= ($end | tonumber))) |
        if length > 0 then
            {
                open: first | .[1],
                high: max_by(.[1]) | .[1],
                low: min_by(.[1]) | .[1],
                close: last | .[1],
                samples: length
            }
        else
            null
        end
    ')
    
    echo "$ohlc"
}

# Função para calcular lucro de swing trading vs buy-and-hold
calculate_swing_profit() {
    local ohlc=$1
    local capital=$2
    
    if [ "$ohlc" = "null" ] || [ -z "$ohlc" ]; then
        echo "null"
        return
    fi
    
    local open=$(echo "$ohlc" | jq -r '.open // 0')
    local high=$(echo "$ohlc" | jq -r '.high // 0')
    local low=$(echo "$ohlc" | jq -r '.low // 0')
    local close=$(echo "$ohlc" | jq -r '.close // 0')
    
    if [ "$open" = "0" ] || [ "$high" = "0" ] || [ "$low" = "0" ]; then
        echo "null"
        return
    fi
    
    # Estratégia perfeita: comprar no mínimo, vender no máximo
    local units_bought=$(echo "scale=8; $capital / $low" | bc)
    local swing_value=$(echo "scale=2; $units_bought * $high" | bc)
    local swing_profit=$(echo "scale=2; $swing_value - $capital" | bc)
    local swing_return=$(echo "scale=2; ($swing_profit / $capital) * 100" | bc)
    
    # Buy-and-hold: comprar na abertura, vender no fecho
    local units_bought_bh=$(echo "scale=8; $capital / $open" | bc)
    local bh_value=$(echo "scale=2; $units_bought_bh * $close" | bc)
    local bh_profit=$(echo "scale=2; $bh_value - $capital" | bc)
    local bh_return=$(echo "scale=2; ($bh_profit / $capital) * 100" | bc)
    
    # Diferença
    local advantage=$(echo "scale=2; $swing_return - $bh_return" | bc)
    
    jq -n \
        --arg open "$open" \
        --arg high "$high" \
        --arg low "$low" \
        --arg close "$close" \
        --arg swing_profit "$swing_profit" \
        --arg swing_return "$swing_return" \
        --arg bh_profit "$bh_profit" \
        --arg bh_return "$bh_return" \
        --arg advantage "$advantage" \
        '{
            open: ($open | tonumber),
            high: ($high | tonumber),
            low: ($low | tonumber),
            close: ($close | tonumber),
            swing: {
                profit_usd: ($swing_profit | tonumber),
                return_pct: ($swing_return | tonumber)
            },
            buyhold: {
                profit_usd: ($bh_profit | tonumber),
                return_pct: ($bh_return | tonumber)
            },
            advantage_pct: ($advantage | tonumber)
        }'
}

# Capital base para simulação (€1000 por ativo)
CAPITAL=1000

# Data do relatório
REPORT_DATE=$(date -Iseconds)
YESTERDAY_DATE=$(date -d "yesterday" +%Y-%m-%d)

# Iniciar relatório JSON
echo "{\"generated_at\": \"$REPORT_DATE\", \"analysis_date\": \"$YESTERDAY_DATE\", \"capital_per_asset\": $CAPITAL, \"assets\": {" > "$REPORT_FILE.tmp"

first=true
for coin in BTC ETH SOL KAS FLUX; do
    echo "Analisando $coin..." >&2
    
    # Buscar dados
    data=$(fetch_ohlc "$coin")
    sleep 2  # Rate limiting
    
    # Extrair OHLC de ontem
    ohlc=$(extract_yesterday_ohlc "$data")
    
    # Calcular lucros
    result=$(calculate_swing_profit "$ohlc" "$CAPITAL")
    
    # Adicionar ao relatório
    if [ "$first" = true ]; then
        first=false
    else
        echo "," >> "$REPORT_FILE.tmp"
    fi
    
    echo "\"$coin\": $result" >> "$REPORT_FILE.tmp"
done

echo "}}" >> "$REPORT_FILE.tmp"

# Formatar e guardar
jq '.' "$REPORT_FILE.tmp" > "$REPORT_FILE"
rm "$REPORT_FILE.tmp"

echo "Análise completa: $REPORT_FILE"
