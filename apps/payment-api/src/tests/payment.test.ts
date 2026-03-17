import request from 'supertest';
import app from '../src/index';

describe('Payment API', () => {
  const testPayment = {
    amount: 100.50,
    currency: 'USD' as const,
    payerId: 'payer_123',
    payeeId: 'payee_456',
    description: 'Test payment',
  };

  let createdPaymentId: string;

  describe('POST /api/v1/payments', () => {
    it('should create a payment successfully', async () => {
      const response = await request(app)
        .post('/api/v1/payments')
        .send(testPayment)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('id');
      expect(response.body.data.amount).toBe(testPayment.amount);
      expect(response.body.data.currency).toBe(testPayment.currency);
      expect(response.body.data.status).toBe('completed');

      createdPaymentId = response.body.data.id;
    });

    it('should reject invalid amount', async () => {
      const response = await request(app)
        .post('/api/v1/payments')
        .send({ ...testPayment, amount: -10 })
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should reject invalid currency', async () => {
      const response = await request(app)
        .post('/api/v1/payments')
        .send({ ...testPayment, currency: 'INVALID' })
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should reject missing required fields', async () => {
      const response = await request(app)
        .post('/api/v1/payments')
        .send({ amount: 100 })
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });

  describe('GET /api/v1/payments/:id', () => {
    it('should get payment by id', async () => {
      const response = await request(app)
        .get(`/api/v1/payments/${createdPaymentId}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.id).toBe(createdPaymentId);
    });

    it('should return 404 for non-existent payment', async () => {
      const response = await request(app)
        .get('/api/v1/payments/non-existent-id')
        .expect(404);

      expect(response.body.success).toBe(false);
    });
  });

  describe('GET /api/v1/payments', () => {
    it('should list payments with pagination', async () => {
      const response = await request(app)
        .get('/api/v1/payments')
        .query({ page: 1, limit: 10 })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeInstanceOf(Array);
      expect(response.body.pagination).toBeDefined();
    });
  });

  describe('POST /api/v1/payments/:id/refund', () => {
    it('should refund a payment', async () => {
      const response = await request(app)
        .post(`/api/v1/payments/${createdPaymentId}/refund`)
        .send({ reason: 'Customer request' })
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('id');
      expect(response.body.data.paymentId).toBe(createdPaymentId);
    });

    it('should reject refund for non-existent payment', async () => {
      const response = await request(app)
        .post('/api/v1/payments/non-existent-id/refund')
        .send({ reason: 'Test' })
        .expect(404);

      expect(response.body.success).toBe(false);
    });
  });
});
