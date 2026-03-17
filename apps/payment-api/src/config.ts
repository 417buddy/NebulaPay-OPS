export const config = {
  environment: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  appVersion: process.env.APP_VERSION || '1.0.0',
  
  // Database
  database: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    name: process.env.DB_NAME || 'nebulapay',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    maxConnections: parseInt(process.env.DB_MAX_CONNECTIONS || '10', 10),
  },
  
  // Redis
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
    password: process.env.REDIS_PASSWORD,
  },
  
  // Security
  allowedOrigins: (process.env.ALLOWED_ORIGINS || '*').split(','),
  rateLimitWindowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000', 10),
  rateLimitMax: parseInt(process.env.RATE_LIMIT_MAX || '100', 10),
  
  // Feature flags
  enableMetrics: process.env.ENABLE_METRICS !== 'false',
  enableSwagger: process.env.ENABLE_SWAGGER !== 'false',
};
