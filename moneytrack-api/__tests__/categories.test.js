const request = require('supertest');
const { app } = require('../src/index');
const { initializeDatabase } = require('../src/db');

describe('Categories API', () => {
  let appInstance;
  let authToken;

  beforeAll(async () => {
    await initializeDatabase();
    const { app: a } = require('../src/index');
    appInstance = a;

    const registerRes = await request(appInstance)
      .post('/api/auth/register')
      .send({ email: 'cats@test.com', password: 'password123' });
    authToken = registerRes.body.data.accessToken;
  });

  afterAll(async () => {
    const fs = require('fs');
    const path = require('path');
    const dbPath = path.join(__dirname, '..', 'moneytrack.db');
    if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
  });

  describe('GET /api/categories', () => {
    it('should return preset categories', async () => {
      const res = await request(appInstance)
        .get('/api/categories')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThan(0);
    });

    it('should include both expense and income preset categories', async () => {
      const res = await request(appInstance)
        .get('/api/categories')
        .set('Authorization', `Bearer ${authToken}`);

      const types = res.body.data.map(c => c.type);
      expect(types).toContain('expense');
      expect(types).toContain('income');
    });

    it('should reject request without auth token', async () => {
      const res = await request(appInstance).get('/api/categories');
      expect(res.status).toBe(401);
    });
  });

  describe('POST /api/categories', () => {
    it('should create a custom expense category', async () => {
      const res = await request(appInstance)
        .post('/api/categories')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'My Custom Expense', type: 'expense', icon: 'X' });

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);
      expect(res.body.data.name).toBe('My Custom Expense');
      expect(res.body.data.type).toBe('expense');
      expect(res.body.data.isPreset).toBe(0);
    });

    it('should create a custom income category', async () => {
      const res = await request(appInstance)
        .post('/api/categories')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'Freelance Income', type: 'income', icon: 'F' });

      expect(res.status).toBe(200);
      expect(res.body.data.type).toBe('income');
    });

    it('should reject category without name', async () => {
      const res = await request(appInstance)
        .post('/api/categories')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ type: 'expense' });

      expect(res.status).toBe(400);
      expect(res.body.code).toBe(400);
    });

    it('should reject category without type', async () => {
      const res = await request(appInstance)
        .post('/api/categories')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'No Type Category' });

      expect(res.status).toBe(400);
      expect(res.body.code).toBe(400);
    });

    it('should reject invalid type value', async () => {
      const res = await request(appInstance)
        .post('/api/categories')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'Invalid Type', type: 'invalid' });

      expect(res.status).toBe(400);
      expect(res.body.code).toBe(400);
    });
  });

  describe('PUT /api/categories/:id', () => {
    let customCategoryId;

    beforeAll(async () => {
      const res = await request(appInstance)
        .post('/api/categories')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'To Be Updated', type: 'expense' });
      customCategoryId = res.body.data.id;
    });

    it('should update custom category name', async () => {
      const res = await request(appInstance)
        .put('/api/categories/' + customCategoryId)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'Updated Name' });

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);
    });

    it('should update custom category icon', async () => {
      const res = await request(appInstance)
        .put('/api/categories/' + customCategoryId)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ icon: 'Z' });

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);
    });

    it('should return 404 for non-existent category', async () => {
      const res = await request(appInstance)
        .put('/api/categories/99999')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'Hacked' });

      expect(res.status).toBe(404);
    });
  });

  describe('DELETE /api/categories/:id', () => {
    let categoryToDelete;

    beforeAll(async () => {
      const res = await request(appInstance)
        .post('/api/categories')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'To Be Deleted', type: 'expense' });
      categoryToDelete = res.body.data.id;
    });

    it('should soft delete a custom category', async () => {
      const res = await request(appInstance)
        .delete('/api/categories/' + categoryToDelete)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);
    });

    it('should return 404 when deleting non-existent category', async () => {
      const res = await request(appInstance)
        .delete('/api/categories/99999')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(404);
    });
  });
});
