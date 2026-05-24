const request = require('supertest');
const { app } = require('../src/index');
const { initializeDatabase } = require('../src/db');

describe('Assets API', () => {
  let appInstance;
  let authToken;

  beforeAll(async () => {
    await initializeDatabase();
    const { app: a } = require('../src/index');
    appInstance = a;

    const registerRes = await request(appInstance)
      .post('/api/auth/register')
      .send({ username: 'assetsuser', password: 'password123' });
    authToken = registerRes.body.data.accessToken;
  });

  afterAll(async () => {
    const fs = require('fs');
    const path = require('path');
    const dbPath = path.join(__dirname, '..', 'moneytrack.db');
    if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
  });

  describe('GET /api/assets', () => {
    it('should return empty array when no assets exist', async () => {
      const res = await request(appInstance)
        .get('/api/assets')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBe(0);
    });

    it('should reject request without auth token', async () => {
      const res = await request(appInstance).get('/api/assets');
      expect(res.status).toBe(401);
    });
  });

  describe('POST /api/assets', () => {
    it('should create a new asset', async () => {
      const res = await request(appInstance)
        .post('/api/assets')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'My Car',
          type: 1,
          subType: 1,
          category: 1,
          amount: 150000,
          note: 'Tesla Model 3'
        });

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);
      expect(res.body.data).toHaveProperty('assetId');
      expect(res.body.data.name).toBe('My Car');
      expect(res.body.data.amount).toBe(150000);
    });

    it('should reject asset without name', async () => {
      const res = await request(appInstance)
        .post('/api/assets')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ type: 1 });

      expect(res.status).toBe(400);
      expect(res.body.code).toBe(400);
    });

    it('should reject asset without type', async () => {
      const res = await request(appInstance)
        .post('/api/assets')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'No Type Asset' });

      expect(res.status).toBe(400);
      expect(res.body.code).toBe(400);
    });

    it('should create asset with default values', async () => {
      const res = await request(appInstance)
        .post('/api/assets')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'Minimal Asset', type: 2 });

      expect(res.status).toBe(200);
      expect(res.body.data.subType).toBe(0);
      expect(res.body.data.category).toBe(1);
      expect(res.body.data.amount).toBe(0);
      expect(res.body.data.isCustom).toBe(0);
    });
  });

  describe('PUT /api/assets/:id', () => {
    let assetId;

    beforeAll(async () => {
      const res = await request(appInstance)
        .post('/api/assets')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'Original Asset', type: 1, subType: 1, category: 1, amount: 1000 });
      assetId = res.body.data.assetId;
    });

    it('should update asset name', async () => {
      const res = await request(appInstance)
        .put(`/api/assets/${assetId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'Updated Asset Name' });

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);
    });

    it('should update asset amount', async () => {
      const res = await request(appInstance)
        .put(`/api/assets/${assetId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ amount: 2000 });

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);
    });

    it('should return 404 for non-existent asset', async () => {
      const res = await request(appInstance)
        .put('/api/assets/99999')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'Hacked' });

      expect(res.status).toBe(404);
    });
  });

  describe('DELETE /api/assets/:id', () => {
    let assetToDelete;

    beforeAll(async () => {
      const res = await request(appInstance)
        .post('/api/assets')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'Asset To Delete', type: 1, subType: 1, category: 1 });
      assetToDelete = res.body.data.assetId;
    });

    it('should soft delete an asset', async () => {
      const res = await request(appInstance)
        .delete(`/api/assets/${assetToDelete}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);

      // Verify it's no longer in list
      const listRes = await request(appInstance)
        .get('/api/assets')
        .set('Authorization', `Bearer ${authToken}`);

      const found = listRes.body.data.find(a => a.assetId === assetToDelete);
      expect(found).toBeUndefined();
    });

    it('should return 404 when deleting non-existent asset', async () => {
      const res = await request(appInstance)
        .delete('/api/assets/99999')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.status).toBe(404);
    });
  });
});
