#!/usr/bin/env node
/**
 * Oura Daily Summary
 * Busca dados do Oura Ring e formata resumo diário
 */

const https = require('https');

// Configuração
const OURA_API_KEY = process.env.OURA_API_KEY || process.env.OURA_PAT;
const OURA_API_BASE = 'api.ouraring.com';

// Helper para pedidos HTTP
function fetch(path) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: OURA_API_BASE,
      path: path,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${OURA_API_KEY}`,
        'Content-Type': 'application/json'
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 400) {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        } else {
          resolve(JSON.parse(data));
        }
      });
    });

    req.on('error', reject);
    req.end();
  });
}

// Formatar data
function formatDate(dateStr) {
  const d = new Date(dateStr);
  return d.toLocaleDateString('pt-PT', { day: '2-digit', month: '2-digit' });
}

// Formatar tempo (horas)
function formatHours(minutes) {
  if (!minutes) return '0h';
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return m > 0 ? `${h}h${m}m` : `${h}h`;
}

// Gerar resumo no novo padrão
function generateSummary(sleepData, readinessData, activityData) {
  const today = new Date().toLocaleDateString('pt-PT', {
    day: '2-digit', month: '2-digit', year: 'numeric'
  });
  const time = new Date().toLocaleTimeString('pt-PT', {
    hour: '2-digit', minute: '2-digit'
  });

  // Dados mais recentes
  const sleep = sleepData?.data?.[0] || {};
  const readiness = readinessData?.data?.[0] || {};
  const activity = activityData?.data?.[0] || {};

  let summary = `## 💍 Resumo Oura Ring ${today} ${time}\n\n`;

  // Prontidão (primeiro - info importante)
  if (readiness.score) {
    summary += `### 🎯 Prontidão\n`;
    summary += `- **Score:** **${readiness.score}**/100\n`;
    if (readiness.temperature_deviation) {
      const temp = readiness.temperature_deviation.toFixed(2);
      summary += `- *Temp:* ${temp > 0 ? '+' : ''}${temp}°C\n`;
    }
    summary += '\n';
  }

  // Sono
  if (sleep.score) {
    summary += `### 😴 Sono\n`;
    summary += `- **Score:** **${sleep.score}**/100\n`;
    if (sleep.total_sleep_duration) {
      summary += `- **Duração:** **${formatHours(sleep.total_sleep_duration / 60)}**\n`;
    }
    if (sleep.deep_sleep_duration) {
      summary += `- Profundo: ${formatHours(sleep.deep_sleep_duration / 60)}\n`;
    }
    if (sleep.rem_sleep_duration) {
      summary += `- REM: ${formatHours(sleep.rem_sleep_duration / 60)}\n`;
    }
    summary += '\n';
  }

  // Atividade
  if (activity.score) {
    summary += `### 🏃 Atividade\n`;
    summary += `- **Score:** **${activity.score}**/100\n`;
    if (activity.steps) {
      summary += `- **Passos:** **${activity.steps.toLocaleString()}**\n`;
    }
    if (activity.active_calories) {
      summary += `- Cal: ${activity.active_calories}\n`;
    }
  }

  return summary;
}

// Main
async function main() {
  if (!OURA_API_KEY) {
    console.error('Erro: OURA_API_KEY ou OURA_PAT não definido');
    process.exit(1);
  }

  try {
    // Data de ontem
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const startDate = yesterday.toISOString().split('T')[0];

    // Buscar dados em paralelo
    const [sleep, readiness, activity] = await Promise.all([
      fetch(`/v2/usercollection/sleep?start_date=${startDate}`),
      fetch(`/v2/usercollection/daily_readiness?start_date=${startDate}`),
      fetch(`/v2/usercollection/daily_activity?start_date=${startDate}`)
    ]);

    // Gerar e imprimir resumo
    const summary = generateSummary(sleep, readiness, activity);
    console.log(summary);

  } catch (error) {
    console.error(`Erro: ${error.message}`);
    process.exit(1);
  }
}

main();
