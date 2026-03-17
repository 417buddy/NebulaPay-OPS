import rateLimit from 'express-rate-limit';
import { Request, Response, NextFunction } from 'express';
import { config } from '../config';
import { logger } from '../utils/logger';

export const rateLimiter = rateLimit({
  windowMs: config.rateLimitWindowMs,
  max: config.rateLimitMax,
  message: {
    success: false,
    error: 'Too many requests, please try again later',
  },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (_req: Request, res: Response, _next: NextFunction) => {
    logger.warn('Rate limit exceeded', {
      ip: _req.ip,
      path: _req.path,
    });
    res.status(429).json({
      success: false,
      error: 'Too many requests, please try again later',
    });
  },
});
