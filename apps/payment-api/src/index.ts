import express, { Application, Request, Response, NextFunction } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { StatusCodes } from 'http-status-codes';
import { config } from './config';
import { logger } from './utils/logger';
import { healthRouter } from './routes/health';
import { paymentRouter } from './routes/payment';
import { metricsRouter } from './routes/metrics';
import { errorHandler } from './middleware/errorHandler';
import { rateLimiter } from './middleware/rateLimiter';

const app: Application = express();

// Security middleware
app.use(helmet());
app.use(cors({
  origin: config.allowedOrigins,
  credentials: true,
}));

// Body parsing
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));

// Rate limiting
app.use(rateLimiter);

// Request logging
app.use((req: Request, _res: Response, next: NextFunction) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('user-agent'),
  });
  next();
});

// Routes
app.use('/health', healthRouter);
app.use('/api/v1/payments', paymentRouter);
app.use('/metrics', metricsRouter);

// Root endpoint
app.get('/', (_req: Request, res: Response) => {
  res.json({
    name: 'NebulaPay Payment API',
    version: config.appVersion,
    status: 'running',
  });
});

// 404 handler
app.use((_req: Request, res: Response) => {
  res.status(StatusCodes.NOT_FOUND).json({
    error: 'Not Found',
    message: `Route ${_req.method} ${_req.path} not found`,
  });
});

// Global error handler
app.use(errorHandler);

const PORT = config.port;

app.listen(PORT, () => {
  logger.info(`🚀 NebulaPay API server running on port ${PORT}`, {
    environment: config.environment,
    version: config.appVersion,
  });
});

export default app;
