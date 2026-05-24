const request = require('supertest');
const { app } = require('../src/index');
const { initializeDatabase } = require('../src/db');

describe('Security', () => {
  let appInstance;

  beforeAll(async () => {
    await initializeDatabase();
    const { app: a } = require('../src/index');
    appInstance = a;
  });

  afterAll(async () => {
    const fs = require('fs');
    const path = require('path');
    const dbPath = path.join(__dirname, '..', 'moneytrack.db');
    if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
  });

  describe('Rate Limiting on Auth Endpoints', () => {
    it('should block login attempts after rate limit exceeded', async () => {
      const email = 'ratelimit5@test.com';
      await request(appInstance)
        .post('/api/auth/register')
        .send({ email, password: 'password123' });

      for (let i = 0; i < 20; i++) {
        await request(appInstance)
          .post('/api/auth/login')
          .send({ email, password: 'wrongpassword' });
      }

      const res = await request(appInstance)
        .post('/api/auth/login')
        .send({ email, password: 'wrongpassword' });

      expect(res.status).toBe(429);
      expect(res.body.code).toBe(429);
      expect(res.body.msg).toContain('Too many requests');
    });

    it('should block registration attempts after rate limit exceeded', async () => {
      for (let i = 0; i < 20; i++) {
        await request(appInstance)
          .post('/api/auth/register')
          .send({ username: 'rapidfix4' + i, password: 'password123' });
      }

      const res = await request(appInstance)
        .post('/api/auth/register')
        .send({ username: 'rapidfix421', password: 'password123' });

      expect(res.status).toBe(429);
      expect(res.body.code).toBe(429);
    });
  });

  describe('CORS', () => {
    it('should include CORS headers on responses', async () => {
      const res = await request(appInstance)
        .post('/api/auth/login')
        .send({ username: 'corsuser', password: 'password123' });

      expect(res.headers).toHaveProperty('access-control-allow-origin');
    });

    it('should handle OPTIONS preflight request', async () => {
      const res = await request(appInstance)
        .options('/api/auth/login');

      expect(res.status).toBe(204);
    });
  });
});
