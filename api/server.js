// api/server.js - servidor Express so para desenvolvimento.
// Todas as rotas vem do mesmo handler da Vercel (api/index.js), assim o que
// roda no computador e igual ao que roda em producao (login, loja, estoque).
import express from 'express';
import cors from 'cors';
import vercelHandler from './index.js';

const app = express();
const PORT = 3001;

app.use(cors());
app.use(express.json({ limit: '5mb' }));

app.all('/api/*', (req, res) => vercelHandler(req, res));

app.listen(PORT, () => {
  console.log(`API rodando em http://localhost:${PORT}`);
});
