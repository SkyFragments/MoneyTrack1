const request = require('supertest');
const { app } = require('../src/index');
const { initializeDatabase } = require('../src/db');

describe('Sync API', () => {
  let appInstance;
  let authToken;

  beforeAll(async () => {
    await initializeDatabase();
    const { app: a } = require('../src/index');
    appInstance = a;

    const registerRes = await request(appInstance)
      .post('/api/auth/register')
      .send({ username: 'syncuser', password: 'password123' });
    authToken = registerRes.body.data.accessToken;
  });

  afterAll(async () => {
    const fs = require('fs');
    const path = require('path');
    const dbPath = path.join(__dirname, '..', 'moneytrack.db');
    if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
  });

  describe('GET /api/sync/pull', () => {
    it('should pull all data for user', async () => {
      const res = await request(appInstance)
        .get('/api/sync/pull')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);
      expect(res.body.data).toHaveProperty('accounts');
      expect(res.body.data).toHaveProperty('transactions');
      expect(res.body.data).toHaveProperty('assets');
      expect(res.body.data).toHaveProperty('budgets');
      expect(res.body.data).toHaveProperty('categories');
      expect(res.body.data).toHaveProperty('serverTime');
    });

    it('should pull categories with isPreset=1', async () => {
      const res = await request(appInstance)
        .get('/api/sync/pull')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.body.data.categories.length).toBeGreaterThan(0);
      expect(res.body.data.categories.every(c => c.isPreset === 1)).toBe(true);
    });

    it('should reject request without auth token', async () => {
      const res = await request(appInstance).get('/api/sync/pull');
      expect(res.status).toBe(401);
    });
  });

  describe('POST /api/sync/push', () => {
    it('should push accounts and return mappings', async () => {
      const res = await request(appInstance)
        .post('/api/sync/push')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          accounts: [
            { id: 'local-1', name: 'Pushed Account', type: 'cash' }
          ],
          transactions: [],
          assets: [],
          budgets: []
        });

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);
      expect(res.body.data.counts.accounts).toBe(1);
      expect(res.body.data.mappings.length).toBe(1);
      expect(res.body.data.mappings[0].localId).toBe('local-1');
      expect(res.body.data.mappings[0].table).toBe('accounts');
    });

    it('should push transactions with localId mapping', async () => {
      // First create an account to reference
      const accountRes = await request(appInstance)
        .post('/api/accounts')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'For Tx Test', type: 'cash' });
      const accountId = accountRes.body.data.accountId;

      const res = await request(appInstance)
        .post('/api/sync/push')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          accounts: [],
          transactions: [
            { localId: 'tx-local-1', accountId: accountId, resource: 101, type: 'expense', amount: 50, date: '2024-01-01' }
          ],
          assets: [],
          budgets: []
        });

      expect(res.status).toBe(200);
      expect(res.body.data.counts.transactions).toBe(1);
      expect(res.body.data.mappings[0].localId).toBe('tx-local-1');
    });

    it('should reject push with invalid data structure', async () => {
      const res = await request(appInstance)
        .post('/api/sync/push')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          accounts: 'not-an-array'
        });

      expect(res.status).toBe(500);
    });

    it('should return zero counts when pushing empty data', async () => {
      const res = await request(appInstance)
        .post('/api/sync/push')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          accounts: [],
          transactions: [],
          assets: [],
          budgets: []
        });

      expect(res.status).toBe(200);
      expect(res.body.data.counts.accounts).toBe(0);
      expect(res.body.data.counts.transactions).toBe(0);
      expect(res.body.data.mappings.length).toBe(0);
    });
  });
});
