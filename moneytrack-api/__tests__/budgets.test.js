const request = require('supertest');
const { app } = require('../src/index');
const { initializeDatabase } = require('../src/db');

describe('Budgets API', () => {
  let appInstance;
  let authToken;
  let accountId;

  beforeAll(async () => {
    await initializeDatabase();
    const { app: a } = require('../src/index');
    appInstance = a;

    const registerRes = await request(appInstance)
      .post('/api/auth/register')
      .send({ email: 'budgets@test.com', password: 'password123' });
    authToken = registerRes.body.data.accessToken;

    const accountRes = await request(appInstance)
      .post('/api/accounts')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name: 'Budget Account', type: 'cash' });
    accountId = accountRes.body.data.accountId;
  });

  afterAll(async () => {
    const fs = require('fs');
    const path = require('path');
    const dbPath = path.join(__dirname, '..', 'moneytrack.db');
    if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
  });

  describe('GET /api/budgets', () => {
    it('should return empty array when no budgets exist', async () => {
      const res = await request(appInstance)
        .get('/api/budgets')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBe(0);
    });

    it('should filter budgets by accountId', async () => {
      await request(appInstance)
        .post('/api/budgets')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ accountId, month: '2024-01', amount: 5000 });

      const res = await request(appInstance)
        .get('/api/budgets?accountId=' + accountId)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBeGreaterThan(0);
      expect(res.body.data[0].accountId).toBe(accountId);
    });

    it('should filter budgets by month', async () => {
      const res = await request(appInstance)
        .get('/api/budgets?month=2024-01')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body.data)).toBe(true);
    });
  });

  describe('POST /api/budgets', () => {
    it('should create a new budget', async () => {
      const res = await request(appInstance)
        .post('/api/budgets')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ accountId, month: '2024-06', amount: 3000 });

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);
      expect(res.body.data).toHaveProperty('id');
      expect(res.body.data.month).toBe('2024-06');
      expect(res.body.data.amount).toBe(3000);
    });

    it('should reject budget without required fields', async () => {
      const res = await request(appInstance)
        .post('/api/budgets')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ accountId });

      expect(res.status).toBe(400);
      expect(res.body.code).toBe(400);
    });

    it('should upsert budget when same accountId and month exists', async () => {
      await request(appInstance)
        .post('/api/budgets')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ accountId, month: '2024-07', amount: 1000 });

      const res = await request(appInstance)
        .post('/api/budgets')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ accountId, month: '2024-07', amount: 2000 });

      expect(res.status).toBe(200);
      expect(res.body.data.amount).toBe(2000);
    });
  });

  describe('PUT /api/budgets/:id', () => {
    let budgetId;

    beforeAll(async () => {
      const res = await request(appInstance)
        .post('/api/budgets')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ accountId, month: '2024-08', amount: 1500 });
      budgetId = res.body.data.id;
    });

    it('should update budget amount', async () => {
      const res = await request(appInstance)
        .put('/api/budgets/' + budgetId)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ amount: 2500 });

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);
    });

    it('should return 404 for non-existent budget', async () => {
      const res = await request(appInstance)
        .put('/api/budgets/99999')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ amount: 999 });

      expect(res.status).toBe(404);
    });
  });

  describe('DELETE /api/budgets/:id', () => {
    let budgetToDelete;

    beforeAll(async () => {
      const res = await request(appInstance)
        .post('/api/budgets')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ accountId, month: '2024-09', amount: 500 });
      budgetToDelete = res.body.data.id;
    });

    it('should soft delete a budget', async () => {
      const res = await request(appInstance)
        .delete('/api/budgets/' + budgetToDelete)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);

      const listRes = await request(appInstance)
        .get('/api/budgets')
        .set('Authorization', `Bearer ${authToken}`);

      const found = listRes.body.data.find(b => b.id === budgetToDelete);
      expect(found).toBeUndefined();
    });
  });
});
