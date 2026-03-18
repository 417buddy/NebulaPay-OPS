import { Router } from 'express';
import promClient from 'prom-client';

const router = Router();

// Collect default metrics
promClient.collectDefaultMetrics({ prefix: 'nebulapay_' });

// Custom metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'nebulapay_http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5],
});

const paymentCounter = new promClient.Counter({
  name: 'nebulapay_payments_total',
  help: 'Total number of payments processed',
  labelNames: ['currency', 'status'],
});

const activeConnections = new promClient.Gauge({
  name: 'nebulapay_active_connections',
  help: 'Number of active connections',
});

// Track requests
router.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration
      .labels(req.method, req.route?.path || req.path, res.statusCode.toString())
      .observe(duration);
  });
  
  next();
});

// Metrics endpoint
router.get('/', async (_req, res) => {
  res.set('Content-Type', promClient.register.contentType);
  res.end(await promClient.register.metrics());
});

export const metricsRouter = router;
export { httpRequestDuration, paymentCounter, activeConnections };
