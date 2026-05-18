require('dotenv').config();
const express = require('express');
const { initializeDatabase } = require('./db');
const authRoutes = require('./routes/auth');
const categoryRoutes = require('./routes/categories');
const syncRoutes = require('./routes/sync');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/categories', categoryRoutes);

app.use('/api/sync', syncRoutes);

// Initialize database and start server
async function start() {
  await initializeDatabase();
  app.listen(PORT, () => {
    console.log(`MoneyTrack API running on port ${PORT}`);
  });
}

start();

module.exports = app;