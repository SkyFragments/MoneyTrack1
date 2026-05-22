const request = require('supertest');
const express = require('express');

// Mock the entire app structure for testing
const jwt = require('jsonwebtoken');

// Build a test app that mirrors the real structure
const { app } = require('../src/index');

describe('Auth API', () => {
  let app;

  beforeAll(async () => {
    // Initialize DB before app is used
    const { initializeDatabase } = require('../src/db');
    await initializeDatabase();
    const { app: expressApp } = require('../src/index');
    app = expressApp;
  });

  afterAll(async () => {
    // Clean up test DB
    const fs = require('fs');
    const path = require('path');
    const dbPath = path.join(__dirname, '..', 'moneytrack.db');
    if (fs.existsSync(dbPath)) {
      fs.unlinkSync(dbPath);
    }
  });

  describe('POST /api/auth/register', () => {
    it('should register a new user successfully', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ email: 'test@example.com', password: 'password123' });

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);
      expect(res.body.data).toHaveProperty('user');
      expect(res.body.data).toHaveProperty('accessToken');
      expect(res.body.data).toHaveProperty('refreshToken');
      expect(res.body.data.user.email).toBe('test@example.com');
    });

    it('should reject registration with missing email', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ password: 'password123' });

      expect(res.status).toBe(400);
      expect(res.body.code).toBe(400);
    });

    it('should reject registration with missing password', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ email: 'test2@example.com' });

      expect(res.status).toBe(400);
      expect(res.body.code).toBe(400);
    });

    it('should reject registration with invalid email format', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ email: 'not-an-email', password: 'password123' });

      expect(res.status).toBe(400);
    });

    it('should reject weak passwords', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ email: 'weak@example.com', password: '123' });

      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/auth/login', () => {
    beforeAll(async () => {
      // Create a test user
      await request(app)
        .post('/api/auth/register')
        .send({ email: 'login@example.com', password: 'password123' });
    });

    it('should login with valid credentials', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: 'login@example.com', password: 'password123' });

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);
      expect(res.body.data).toHaveProperty('accessToken');
      expect(res.body.data).toHaveProperty('refreshToken');
    });

    it('should reject invalid password', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: 'login@example.com', password: 'wrongpassword' });

      expect(res.status).toBe(401);
      expect(res.body.code).toBe(401);
    });

    it('should reject non-existent user', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: 'nonexistent@example.com', password: 'password123' });

      expect(res.status).toBe(401);
      expect(res.body.code).toBe(401);
    });
  });

  describe('POST /api/auth/refresh', () => {
    let refreshToken;

    beforeAll(async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ email: 'refresh@example.com', password: 'password123' });
      refreshToken = res.body.data.refreshToken;
    });

    it('should refresh access token', async () => {
      const res = await request(app)
        .post('/api/auth/refresh')
        .send({ refreshToken });

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);
      expect(res.body.data).toHaveProperty('accessToken');
      expect(res.body.data).toHaveProperty('refreshToken');
    });

    it('should reject invalid refresh token', async () => {
      const res = await request(app)
        .post('/api/auth/refresh')
        .send({ refreshToken: 'invalid-token' });

      expect(res.status).toBe(401);
    });
  });

  describe('GET /api/auth/me', () => {
    let accessToken;

    beforeAll(async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ email: 'me@example.com', password: 'password123' });
      accessToken = res.body.data.accessToken;
    });

    it('should get current user info', async () => {
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${accessToken}`);

      expect(res.status).toBe(200);
      expect(res.body.code).toBe(0);
      expect(res.body.data).toHaveProperty('email');
    });

    it('should reject request without token', async () => {
      const res = await request(app).get('/api/auth/me');

      expect(res.status).toBe(401);
    });

    it('should reject request with invalid token', async () => {
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', 'Bearer invalid-token');

      expect(res.status).toBe(401);
    });
  });
});
