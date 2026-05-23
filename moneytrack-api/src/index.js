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

// Validate JWT_SECRET on startup
if (!process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET environment variable is required but not set');
}

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// CORS - allow HarmonyOS and web clients
app.use(cors({
  origin: '*',
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
app.use('/api/guest', guestRoutes);

// Protected routes (require auth)
app.use('/api/categories', authMiddleware, categoryRoutes);
app.use('/api/accounts', authMiddleware, accountRoutes);
app.use('/api/transactions', authMiddleware, transactionRoutes);
app.use('/api/assets', authMiddleware, assetRoutes);
app.use('/api/budgets', authMiddleware, budgetRoutes);
app.use('/api/sync', authMiddleware, syncRoutes);

// Initialize database and start server
async function start() {
  await initializeDatabase();
  app.listen(PORT, () => {
    console.log(`MoneyTrack API running on port ${PORT}`);
  });
}

// Only start server when run directly (not when imported for testing)
if (require.main === module) {
  start();
}

module.exports = { app, start };