require('dotenv').config();
const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const { initializeDatabase } = require('./db');
const authMiddleware = require('./middleware/auth');
const authRoutes = require('./routes/auth');
const guestRoutes = require('./routes/guest');
const categoryRoutes = require('./routes/categories');
const accountRoutes = require('./routes/accounts');
const transactionRoutes = require('./routes/transactions');
const assetRoutes = require('./routes/assets');
const budgetRoutes = require('./routes/budgets');
const syncRoutes = require('./routes/sync');
const userRoutes = require('./routes/user');

// Validate JWT_SECRET on startup
if (!process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET environment variable is required but not set');
}

const app = express();
const PORT = process.env.PORT || 3000;

// Request logging middleware
app.use((req, res, next) => {
  const start = Date.now();
  console.log(`[${new Date().toISOString()}] >>> INCOMING ${req.method} ${req.originalUrl}`);
  console.log(`[${new Date().toISOString()}]     remoteAddr=${req.ip || req.socket.remoteAddress}`);
  console.log(`[${new Date().toISOString()}]     userAgent=${req.get('User-Agent') || 'none'}`);
  console.log(`[${new Date().toISOString()}]     contentType=${req.get('Content-Type') || 'none'}`);
  console.log(`[${new Date().toISOString()}]     accept=${req.get('Accept') || 'none'}`);
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`[${new Date().toISOString()}] <<< RESPONSE ${req.method} ${req.originalUrl} - ${res.statusCode} (${duration}ms)`);
  });
  next();
});

// Middleware
app.use(express.json());

// CORS - allow HarmonyOS and web clients
// NOTE: In production, restrict origin via ALLOWED_ORIGIN env var
app.use(cors({
  origin: process.env.ALLOWED_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Rate limiting for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // 20 requests per window
  standardHeaders: true,
  legacyHeaders: false,
  message: { code: 429, msg: 'Too many requests, please try again later' }
});

// Auth routes (public, with rate limiting)
app.use('/api/auth', authLimiter, authRoutes);

// Guest routes (public, for creating guest accounts)
app.use('/api/guest', authLimiter, guestRoutes);

// Protected routes (require auth)
app.use('/api/categories', authMiddleware, categoryRoutes);
app.use('/api/accounts', authMiddleware, accountRoutes);
app.use('/api/transactions', authMiddleware, transactionRoutes);
app.use('/api/assets', authMiddleware, assetRoutes);
app.use('/api/budgets', authMiddleware, budgetRoutes);
app.use('/api/sync', authMiddleware, syncRoutes);
app.use('/api/user', authMiddleware, userRoutes);

// Initialize database and start server
async function start() {
  await initializeDatabase();
  // Bind to all network interfaces so mobile device can connect
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`[SERVER] MoneyTrack API running on 0.0.0.0:${PORT}`);
    console.log(`[SERVER] Accessible at http://1.12.234.7:${PORT}`);
    console.log(`[SERVER] Health check: http://1.12.234.7:${PORT}/health`);
  });
}

// Only start server when run directly (not when imported for testing)
if (require.main === module) {
  start();
}

module.exports = { app, start };