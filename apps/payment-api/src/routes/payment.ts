import { Router, Request, Response, NextFunction } from 'express';
import { StatusCodes } from 'http-status-codes';
import { z } from 'zod';
import { PaymentService } from '../services/paymentService';
import { logger } from '../utils/logger';

const router = Router();
const paymentService = new PaymentService();

// Schema validation
const paymentSchema = z.object({
  amount: z.number().positive(),
  currency: z.enum(['USD', 'EUR', 'GBP', 'NGN']),
  payerId: z.string().min(1),
  payeeId: z.string().min(1),
  description: z.string().optional(),
  metadata: z.record(z.unknown()).optional(),
});

// POST /api/v1/payments - Create payment
router.post('/', async (req: Request, res: Response) => {
  try {
    const validatedData = paymentSchema.parse(req.body);
    
    const payment = await paymentService.createPayment(validatedData);
    
    logger.info('Payment created successfully', { 
      paymentId: payment.id,
      amount: payment.amount,
      currency: payment.currency,
    });
    
    res.status(StatusCodes.CREATED).json({
      success: true,
      data: payment,
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        error: 'Validation error',
        details: error.errors,
      });
      return;
    }
    throw error;
  }
});

// GET /api/v1/payments/:id - Get payment by ID
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  
  const payment = await paymentService.getPaymentById(id);
  
  if (!payment) {
    res.status(StatusCodes.NOT_FOUND).json({
      success: false,
      error: 'Payment not found',
    });
    return;
  }
  
  res.json({
    success: true,
    data: payment,
  });
});

// GET /api/v1/payments - List payments
router.get('/', async (_req: Request, res: Response) => {
  const page = parseInt(_req.query.page as string) || 1;
  const limit = parseInt(_req.query.limit as string) || 10;
  
  const payments = await paymentService.listPayments({ page, limit });
  
  res.json({
    success: true,
    data: payments,
    pagination: {
      page,
      limit,
      total: payments.length,
    },
  });
});

// POST /api/v1/payments/:id/refund - Refund payment
router.post('/:id/refund', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const { amount, reason } = req.body;
    
    const refund = await paymentService.refundPayment(id, { amount, reason });
    
    logger.info('Payment refunded', { paymentId: id, refundId: refund.id });
    
    res.status(StatusCodes.CREATED).json({
      success: true,
      data: refund,
    });
  } catch (error) {
    next(error);
  }
});

export const paymentRouter = router;
