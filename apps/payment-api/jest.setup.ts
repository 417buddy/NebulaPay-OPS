// Mock config for testing
jest.mock('./src/config', () => ({
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
