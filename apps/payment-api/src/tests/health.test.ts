import request from 'supertest';
import app from '../index';

// Mock config for tests
jest.mock('../config', () => ({
  config: {
    environment: 'test',
    port: 3001,
    appVersion: '1.0.0-test',
    database: {
      host: 'localhost',
      port: 5432,
      name: 'nebulapay_test',
      user: 'postgres',
      password: 'postgres',
      maxConnections: 10,
    },
    redis: {
      host: 'localhost',
      port: 6379,
      password: undefined,
    },
    allowedOrigins: ['*'],
    rateLimitWindowMs: 60000,
    rateLimitMax: 100,
    enableMetrics: false,
    enableSwagger: false,
  },
}));

describe('Health Endpoints', () => {
  describe('GET /health', () => {
    it('should return healthy status', async () => {
      const response = await request(app).get('/health');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('uptime');
    });
  });

  describe('GET /health/live', () => {
    it('should return alive status', async () => {
      const response = await request(app).get('/health/live');
      
      expect(response.status).toBe(200);
      expect(response.body).toEqual({ status: 'alive' });
    });
  });

  describe('GET /health/ready', () => {
    it('should return ready status', async () => {
      const response = await request(app).get('/health/ready');
      
      expect(response.status).toBe(200);
      expect(response.body.status).toBe('ready');
      expect(response.body.checks).toBeDefined();
    });
  });
});

describe('Root Endpoint', () => {
  it('should return API info', async () => {
    const response = await request(app).get('/');
    
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('name', 'NebulaPay Payment API');
    expect(response.body).toHaveProperty('version');
    expect(response.body).toHaveProperty('status', 'running');
  });
});

describe('404 Handler', () => {
  it('should return not found for unknown routes', async () => {
    const response = await request(app).get('/unknown-route');
    
    expect(response.status).toBe(404);
    expect(response.body).toHaveProperty('error', 'Not Found');
  });
});
