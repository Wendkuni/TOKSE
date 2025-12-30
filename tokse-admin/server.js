// Serveur Express minimal pour exposer l'API de création d'autorité
import dotenv from 'dotenv';
dotenv.config();

import bodyParser from 'body-parser';
import cors from 'cors';
import express from 'express';
import createAuthority from './api/create-authority.js';
import updateAuthority from './api/update-authority.js';
import getOrphanAgents from './api/get-orphan-agents.js';
import deleteOrphanAgent from './api/delete-orphan-agent.js';
import deleteAllOrphanAgents from './api/delete-all-orphan-agents.js';
import updateAgentPassword from './api/update-agent-password.js';
import createAgent from './api/create-agent.js';

const app = express();
const PORT = process.env.PORT || 4000;
app.use(cors({
  origin: 'http://localhost:5173',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type'],
}));

app.use(bodyParser.json());
app.use('/api/create-authority', createAuthority);
app.use('/api/update-authority', updateAuthority);
app.use('/api/get-orphan-agents', getOrphanAgents);
app.use('/api/delete-orphan-agent', deleteOrphanAgent);
app.use('/api/delete-all-orphan-agents', deleteAllOrphanAgents);
app.use('/api/update-agent-password', updateAgentPassword);
app.use('/api/create-agent', createAgent);

app.listen(PORT, () => {
  console.log(`API server running on http://localhost:${PORT}`);
});
