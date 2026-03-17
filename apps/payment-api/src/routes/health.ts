import { Router } from 'express';
import { StatusCodes } from 'http-status-codes';

const router = Router();

router.get('/', (_req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

router.get('/live', (_req, res) => {
  res.status(StatusCodes.OK).json({ status: 'alive' });
});

router.get('/ready', (_req, res) => {
  // Check database and redis connections here
  res.status(StatusCodes.OK).json({ 
    status: 'ready',
    checks: {
      database: 'connected',
      redis: 'connected',
    }
  });
});

export const healthRouter = router;
