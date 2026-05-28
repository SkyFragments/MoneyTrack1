const request = require('supertest');
const express = require('express');

// Build a test app that mirrors the real structure
const jwt = require('jsonwebtoken');

const { app } = require('../src/index');

describe('Auth API - Bug Regression Tests', () => {
  let app;

  beforeAll(async () => {
    const { initializeDatabase } = require('../src/db');
    await initializeDatabase();
    const { app: expressApp } = require('../src/index');
    app = expressApp;
  });

  afterAll(async () => {
    const fs = require('fs');
    const path = require('path');
    const dbPath = path.join(__dirname, '..', 'moneytrack.db');
    if (fs.existsSync(dbPath)) {
      fs.unlinkSync(dbPath);
    }
  });

  /**
   * BUG #4: Frontend Request.ets error response handling
   *
   * When backend returns HTTP status 401 with JSON body { code: 401, msg: 'Invalid credentials' },
   * the frontend Request.ets doRequest() creates an ErrorResponse with msg='HTTP 401'
   * BEFORE attempting to parse the actual JSON body.
   *
   * This loses the helpful backend error message ('Invalid credentials') and
   * replaces it with a generic 'HTTP 401' string.
   *
   * BUG LOCATION: commons/lib_network/src/main/ets/https/Request.ets lines 77-82
   *
   * RED phase: This test documents the expected behavior (frontend should preserve backend msg)
   * The frontend bug means users see 'HTTP 401' instead of 'Invalid credentials' or similar.
   */
  describe('POST /api/auth/login - Error Response Structure', () => {
    beforeAll(async () => {
      // Create a test user
      await request(app)
        .post('/api/auth/register')
        .send({ username: 'erruser', password: 'password123' });
    });

    it('should return 401 with meaningful msg (not generic HTTP status)', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ username: 'erruser', password: 'wrongpassword' });

      // The backend correctly returns a meaningful message
      expect(res.status).toBe(401);
      expect(res.body.code).toBe(401);
      expect(res.body.msg).toBeDefined();
      // This passes because backend is correct
      // BUT: Frontend Request.ets ignores this body and returns msg='HTTP 401' instead
      expect(res.body.msg).not.toBe('HTTP 401');
      expect(['Invalid credentials', 'Invalid username or password']).toContain(res.body.msg);
    });

    it('should return 401 with code=401 and msg for non-existent user', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ username: 'nonexistent_user_12345', password: 'password123' });

      expect(res.status).toBe(401);
      expect(res.body.code).toBe(401);
      expect(res.body.msg).toBeDefined();
      expect(res.body.msg).toBeTruthy();
    });

    it('should return 200 with code=0 only on correct credentials', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ username: 'erruser', password: 'password123' });

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);
      expect(res.body.data).toHaveProperty('accessToken');
      expect(res.body.data).toHaveProperty('refreshToken');
    });
  });

  /**
   * BUG #4 continued: Backend error message clarity
   *
   * The error messages 'Invalid credentials' should be consistent whether
   * the user doesn't exist or the password is wrong (security best practice)
   * but the HTTP status codes should differ appropriately.
   */
  describe('POST /api/auth/login - Security Best Practice', () => {
    it('should NOT reveal whether username exists on failed login', async () => {
      const res1 = await request(app)
        .post('/api/auth/login')
        .send({ username: 'nonexistent_xyz', password: 'password123' });

      const res2 = await request(app)
        .post('/api/auth/login')
        .send({ username: 'erruser', password: 'wrongpassword' });

      // Both should give similar error messages to prevent username enumeration
      // (current backend already does this - good!)
      expect(res1.body.msg).toBe(res2.body.msg);
    });
  });
});