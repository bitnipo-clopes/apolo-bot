#!/usr/bin/env node
/**
 * Script de análise de swing trading para crypto
 * Usa dados de mercado da CoinGecko para calcular swing vs buy-and-hold
 */

const fs = require('fs');
const path = require('path');

const COINS = {
  BTC: { name: 'Bitcoin', coingecko_id: 'bitcoin', symbol: 'btc', decimals: 2 },
  ETH: { name: 'Ethereum', coingecko_id: 'ethereum', symbol: 'eth', decimals: 2 },
  SOL: { name: 'Solana', coingecko_id: 'solana', symbol: 'sol', decimals: 2 },
  KAS: { name: 'Kaspa', coingecko_id: 'kaspa', symbol: 'kas', decimals: 6 },
  FLUX: { name: 'Flux', coingecko_id: 'zelcash', symbol: 'flux', decimals: 6 }
};

const CAPITAL_PER_ASSET = 1000;
const DATA_FILE = path.join(__dirname, 'crypto_prices.json');
const OUTPUT_FILE = path.join(__dirname, 'swing_analysis.json');

// Função para fazer fetch com retry e backoff
async function fetchWithRetry(url, retries = 3, delay = 2000) {
  for (let i = 0; i < retries; i++) {
    try {
      const response = await fetch(url);
      if (response.status === 429) {
        // Rate limited - esperar mais tempo
        const waitTime = delay * (i + 1) * 2;
        console.log(`  ⏳ Rate limit atingido, a aguardar ${waitTime}ms...`);
        await new Promise(r => setTimeout(r, waitTime));
        continue;
      }
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      return await response.json();
    } catch (error) {
      if (i === retries - 1) throw error;
      await new Promise(r => setTimeout(r, delay * (i + 1)));
    }
  }
  throw new Error('Max retries exceeded');
}

// Buscar dados de mercado para todos os coins de uma vez
async function getMarketData() {
  const ids = Object.values(COINS).map(c => c.coingecko_id).join(',');
  const url = `https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=${ids}&order=market_cap_desc&sparkline=false&price_change_percentage=24h`;
  
  const data = await fetchWithRetry(url, 5, 3000);
  
  // Mapear por ID
  const mapped = {};
  for (const item of data) {
    const coin = Object.entries(COINS).find(([_, c]) => c.coingecko_id === item.id);
    if (coin) {
      mapped[coin[0]] = {
        current_price: item.current_price,
        high_24h: item.high_24h,
        low_24h: item.low_24h,
        price_change_24h: item.price_change_percentage_24h,
        ath: item.ath,
        atl: item.atl
      };
    }
  }
  return mapped;
}

// Buscar dados OHLCV para um coin (para dados históricos mais precisos)
async function getOHLCVData(coinId, days = 2) {
  const url = `https://api.coingecko.com/api/v3/coins/${coinId}/ohlc?vs_currency=usd&days=${days}`;
  return await fetchWithRetry(url, 3, 2000);
}

// Calcular análise de swing usando dados de mercado (24h high/low)
function analyzeSwingFromMarketData(symbol, marketData, coinConfig) {
  const { current_price, high_24h, low_24h, price_change_24h } = marketData;
  
  if (!high_24h || !low_24h || high_24h <= low_24h) {
    throw new Error('Dados de mercado inválidos (high/low)');
  }
  
  // Estimar preço de abertura baseado na variação de 24h
  // price_change_24h é a variação percentual desde 24h atrás
  const openPrice = current_price / (1 + (price_change_24h / 100));
  
  // Estratégia Swing: Comprar no mínimo das últimas 24h, vender no máximo
  const buyPrice = low_24h;
  const sellPrice = high_24h;
  
  const quantity = CAPITAL_PER_ASSET / buyPrice;
  const swingProfit = quantity * (sellPrice - buyPrice);
  const swingReturn = ((sellPrice - buyPrice) / buyPrice) * 100;
  
  // Buy-and-hold: Comprar no open (estimado), valor atual
  const buyholdQuantity = CAPITAL_PER_ASSET / openPrice;
  const buyholdValue = buyholdQuantity * current_price;
  const buyholdProfit = buyholdValue - CAPITAL_PER_ASSET;
  const buyholdReturn = price_change_24h;
  
  // Vantagem do swing sobre buy-and-hold
  const advantage = swingReturn - buyholdReturn;
  
  return {
    open: openPrice,
    high: high_24h,
    low: low_24h,
    close: current_price,
    current_price,
    swing: {
      buy_price: buyPrice,
      sell_price: sellPrice,
      profit_usd: swingProfit,
      return_pct: swingReturn
    },
    buyhold: {
      buy_price: openPrice,
      current_value: buyholdValue,
      profit_usd: buyholdProfit,
      return_pct: buyholdReturn
    },
    advantage_pct: advantage,
    data_source: 'market_24h'
  };
}

// Verificar se os dados parecem válidos
function validateData(symbol, analysis) {
  const { current_price, high, low } = analysis;
  
  // Verificar valores nulos ou zero
  if (!current_price || current_price <= 0) {
    return { valid: false, reason: 'Preço atual inválido' };
  }
  
  // Verificar se high > low
  if (!high || !low || high <= low) {
    return { valid: false, reason: 'High <= Low (dados inválidos)' };
  }
  
  // Verificar mudanças extremas (possível erro de dados)
  const range = high - low;
  const rangePct = (range / low) * 100;
  
  // Se o range for maior que 50%, pode ser suspeito
  if (rangePct > 50) {
    console.warn(`  ⚠️ ${symbol}: Range de ${rangePct.toFixed(1)}% nas últimas 24h (volatilidade extrema)`);
  }
  
  return { valid: true };
}

// Gerar relatório formatado
function generateReport(analysisData, analysisDate) {
  let report = `📊 **Análise Swing Trading vs Buy-and-Hold**\n`;
  report += `📅 Data: ${analysisDate}\n`;
  report += `💰 Capital simulado: €${CAPITAL_PER_ASSET.toLocaleString('pt-PT')} por ativo\n`;
  report += `📈 Período: Últimas 24h (High/Low)\n\n`;
  
  let totalSwingProfit = 0;
  let totalBuyholdProfit = 0;
  const assetCount = Object.keys(analysisData.assets).length;
  
  for (const [symbol, data] of Object.entries(analysisData.assets)) {
    const coin = COINS[symbol];
    const swing = data.swing;
    const buyhold = data.buyhold;
    
    totalSwingProfit += swing.profit_usd;
    totalBuyholdProfit += buyhold.profit_usd;
    
    const swingEmoji = swing.return_pct > 0 ? '🟢' : '🔴';
    const buyholdEmoji = buyhold.return_pct > 0 ? '🟢' : '🔴';
    const advantageEmoji = data.advantage_pct > 0 ? '✅' : '⚠️';
    
    report += `**${symbol}** (${coin.name})\n`;
    report += `  ${swingEmoji} Swing: ${swing.return_pct.toFixed(2)}% (€${swing.profit_usd.toFixed(2)})\n`;
    report += `  ${buyholdEmoji} Buy&Hold: ${buyhold.return_pct > 0 ? '+' : ''}${buyhold.return_pct.toFixed(2)}% (€${buyhold.profit_usd.toFixed(2)})\n`;
    report += `  ${advantageEmoji} Vantagem Swing: ${data.advantage_pct > 0 ? '+' : ''}${data.advantage_pct.toFixed(2)}%\n`;
    report += `  📈 Range 24h: $${data.low.toFixed(coin.decimals)} → $${data.high.toFixed(coin.decimals)}\n\n`;
  }
  
  const totalCapital = CAPITAL_PER_ASSET * assetCount;
  const swingTotalPct = (totalSwingProfit / totalCapital) * 100;
  const buyholdTotalPct = (totalBuyholdProfit / totalCapital) * 100;
  
  report += `**Resumo Portfolio (€${totalCapital.toLocaleString('pt-PT')} total)**\n`;
  report += `  🎯 Swing total: €${totalSwingProfit.toFixed(2)} (${swingTotalPct > 0 ? '+' : ''}${swingTotalPct.toFixed(2)}%)\n`;
  report += `  📦 Buy&Hold total: €${totalBuyholdProfit.toFixed(2)} (${buyholdTotalPct > 0 ? '+' : ''}${buyholdTotalPct.toFixed(2)}%)\n`;
  report += `  📊 Diferença: €${(totalSwingProfit - totalBuyholdProfit).toFixed(2)} a favor do ${totalSwingProfit > totalBuyholdProfit ? 'Swing' : 'Buy&Hold'}\n`;
  
  if (analysisData.errors && analysisData.errors.length > 0) {
    report += `\n⚠️ **Avisos:**\n`;
    for (const err of analysisData.errors) {
      report += `  • ${err.symbol}: ${err.reason}\n`;
    }
  }
  
  return report;
}

async function main() {
  console.log('🚀 Iniciando análise de swing trading...\n');
  
  const results = {};
  const errors = [];
  const analysisDate = new Date().toISOString().split('T')[0];
  
  try {
    console.log('📡 A buscar dados de mercado...');
    const marketData = await getMarketData();
    
    console.log(`✅ Dados recebidos para ${Object.keys(marketData).length} ativos\n`);
    
    for (const [symbol, config] of Object.entries(COINS)) {
      try {
        console.log(`📈 A processar ${symbol}...`);
        
        const data = marketData[symbol];
        if (!data) {
          throw new Error('Dados não disponíveis na API');
        }
        
        // Calcular análise
        const analysis = analyzeSwingFromMarketData(symbol, data, config);
        
        // Validar dados
        const validation = validateData(symbol, analysis);
        if (!validation.valid) {
          console.warn(`  ⚠️ ${symbol}: ${validation.reason}`);
          errors.push({ symbol, reason: validation.reason });
          continue;
        }
        
        results[symbol] = analysis;
        console.log(`  ✅ ${symbol}: Swing ${analysis.swing.return_pct.toFixed(2)}% vs Buy&Hold ${analysis.buyhold.return_pct.toFixed(2)}%`);
        
      } catch (error) {
        console.error(`  ❌ ${symbol}: ${error.message}`);
        errors.push({ symbol, reason: error.message });
      }
    }
    
  } catch (error) {
    console.error('❌ Erro ao buscar dados de mercado:', error.message);
    errors.push({ symbol: 'ALL', reason: error.message });
  }
  
  // Guardar resultados
  const output = {
    generated_at: new Date().toISOString(),
    analysis_date: analysisDate,
    capital_per_asset: CAPITAL_PER_ASSET,
    assets: results,
    errors: errors.length > 0 ? errors : undefined
  };
  
  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(output, null, 2));
  console.log(`\n💾 Análise guardada em: ${OUTPUT_FILE}`);
  
  // Gerar e mostrar relatório
  const report = generateReport(output, analysisDate);
  console.log('\n' + report);
  
  // Guardar relatório formatado
  const reportFile = path.join(__dirname, 'swing_report.txt');
  fs.writeFileSync(reportFile, report);
  console.log(`📝 Relatório guardado em: ${reportFile}`);
  
  return { output, report };
}

// Se executado diretamente
if (require.main === module) {
  main().catch(error => {
    console.error('Erro fatal:', error);
    process.exit(1);
  });
}

module.exports = { main, analyzeSwingFromMarketData, generateReport };
