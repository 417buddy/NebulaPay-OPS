import { BadRequestError, NotFoundError } from '../models/error';

export interface Payment {
  id: string;
  amount: number;
  currency: string;
  payerId: string;
  payeeId: string;
  status: 'pending' | 'completed' | 'failed' | 'refunded';
  description?: string;
  metadata?: Record<string, unknown>;
  createdAt: Date;
  updatedAt: Date;
}

export interface Refund {
  id: string;
  paymentId: string;
  amount: number;
  reason?: string;
  status: 'pending' | 'completed' | 'failed';
  createdAt: Date;
}

export interface PaymentFilters {
  page: number;
  limit: number;
  status?: string;
  startDate?: Date;
  endDate?: Date;
}

// In-memory store (replace with database in production)
const payments: Map<string, Payment> = new Map();
const refunds: Map<string, Refund> = new Map();

export class PaymentService {
  async createPayment(data: {
    amount: number;
    currency: string;
    payerId: string;
    payeeId: string;
    description?: string;
    metadata?: Record<string, unknown>;
  }): Promise<Payment> {
    // Validate amount
    if (data.amount <= 0) {
      throw new BadRequestError('Amount must be positive', 'INVALID_AMOUNT');
    }

    const id = this.generateId('pay');
    const now = new Date();

    const payment: Payment = {
      id,
      ...data,
      status: 'completed',
      createdAt: now,
      updatedAt: now,
    };

    payments.set(id, payment);

    // Simulate async operation
    await this.sleep(50);

    return payment;
  }

  async getPaymentById(id: string): Promise<Payment | null> {
    await this.sleep(20);
    return payments.get(id) || null;
  }

  async listPayments(filters: PaymentFilters): Promise<Payment[]> {
    await this.sleep(30);
    const allPayments = Array.from(payments.values());
    const start = (filters.page - 1) * filters.limit;
    const end = start + filters.limit;
    return allPayments.slice(start, end);
  }

  async refundPayment(
    paymentId: string,
    data: { amount?: number; reason?: string }
  ): Promise<Refund> {
    const payment = payments.get(paymentId);

    if (!payment) {
      throw new NotFoundError('Payment not found', 'PAYMENT_NOT_FOUND');
    }

    if (payment.status === 'refunded') {
      throw new BadRequestError('Payment already refunded', 'ALREADY_REFUNDED');
    }

    const id = this.generateId('ref');
    const refundAmount = data.amount || payment.amount;

    const refund: Refund = {
      id,
      paymentId,
      amount: refundAmount,
      reason: data.reason,
      status: 'completed',
      createdAt: new Date(),
    };

    refunds.set(id, refund);

    // Update payment status
    payment.status = 'refunded';
    payment.updatedAt = new Date();
    payments.set(paymentId, payment);

    await this.sleep(50);

    return refund;
  }

  private generateId(prefix: string): string {
    return `${prefix}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
