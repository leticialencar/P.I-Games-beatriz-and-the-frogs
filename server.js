const http = require('node:http');
const fs = require('node:fs/promises');
const path = require('node:path');

const root = __dirname;
const publicDir = path.join(root, 'build', 'web');
const dataPath = path.join(root, 'db.json');
const port = Number(process.env.PORT || 3000);

const mimeTypes = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8', '.png': 'image/png',
  '.wasm': 'application/wasm', '.pck': 'application/octet-stream',
  '.mp3': 'audio/mpeg', '.wav': 'audio/wav',
};

async function readScores() {
  try {
    const data = JSON.parse(await fs.readFile(dataPath, 'utf8'));
    return Array.isArray(data.scores) ? data.scores : [];
  } catch { return []; }
}

async function writeScores(scores) {
  const payload = JSON.stringify({ scores }, null, 2) + '\n';
  await fs.writeFile(`${dataPath}.tmp`, payload);
  await fs.rename(`${dataPath}.tmp`, dataPath);
}

function ranking(scores) {
  return scores.sort((a, b) => b.score - a.score || a.time_ms - b.time_ms).slice(0, 10);
}

function send(res, status, body, type = 'application/json; charset=utf-8') {
  res.writeHead(status, { 'Content-Type': type, 'Cache-Control': 'no-store' });
  res.end(typeof body === 'string' || Buffer.isBuffer(body) ? body : JSON.stringify(body));
}

async function readBody(req) {
  let raw = '';
  for await (const chunk of req) {
    raw += chunk;
    if (raw.length > 10_000) throw new Error('Payload grande demais');
  }
  return JSON.parse(raw || '{}');
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  try {
    if (url.pathname === '/api/leaderboard' && req.method === 'GET') {
      return send(res, 200, { scores: ranking(await readScores()) });
    }
    if (url.pathname === '/api/scores' && req.method === 'POST') {
      const input = await readBody(req);
      const name = String(input.name || '').trim().replace(/\s+/g, ' ').slice(0, 32);
      const score = Number.parseInt(input.score, 10);
      const timeMs = Number(input.time_ms);
      if (!name || !Number.isFinite(score) || score < 1 || !Number.isFinite(timeMs) || timeMs < 0) {
        return send(res, 400, { error: 'Pontuação inválida.' });
      }
      const scores = await readScores();
      scores.push({ name, score, time_ms: Math.round(timeMs), created_at: new Date().toISOString() });
      const top = ranking(scores);
      await writeScores(top);
      return send(res, 201, { scores: top });
    }

    const requested = url.pathname === '/' ? '/index.html' : url.pathname;
    const filePath = path.resolve(publicDir, `.${requested}`);
    if (!filePath.startsWith(publicDir + path.sep)) return send(res, 403, 'Acesso negado', 'text/plain');
    const file = await fs.readFile(filePath);
    send(res, 200, file, mimeTypes[path.extname(filePath)] || 'application/octet-stream');
  } catch (error) {
    if (error.code === 'ENOENT') return send(res, 404, { error: 'Não encontrado.' });
    console.error(error);
    send(res, 500, { error: 'Erro interno.' });
  }
});

server.listen(port, () => console.log(`Beatriz e os Sapinhos em http://localhost:${port}`));
