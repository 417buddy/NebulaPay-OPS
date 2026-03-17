-- NebulaPay Database Initialization

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create payments table
CREATE TABLE IF NOT EXISTS payments (
    id VARCHAR(50) PRIMARY KEY,
    amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL,
    payer_id VARCHAR(100) NOT NULL,
    payee_id VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    description TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create refunds table
CREATE TABLE IF NOT EXISTS refunds (
    id VARCHAR(50) PRIMARY KEY,
    payment_id VARCHAR(50) NOT NULL REFERENCES payments(id),
    amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
    reason TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_payer ON payments(payer_id);
CREATE INDEX IF NOT EXISTS idx_payments_payee ON payments(payee_id);
CREATE INDEX IF NOT EXISTS idx_payments_created ON payments(created_at);
CREATE INDEX IF NOT EXISTS idx_refunds_payment ON refunds(payment_id);

-- Insert sample data
INSERT INTO payments (id, amount, currency, payer_id, payee_id, status, description) VALUES
('pay_sample_001', 150.00, 'USD', 'customer_001', 'merchant_001', 'completed', 'Sample payment 1'),
('pay_sample_002', 250.50, 'EUR', 'customer_002', 'merchant_001', 'completed', 'Sample payment 2'),
('pay_sample_003', 75.25, 'GBP', 'customer_001', 'merchant_002', 'pending', 'Sample payment 3')
ON CONFLICT (id) DO NOTHING;
