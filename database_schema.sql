-- QR Collection Project Database Schema
-- Supports multiple clients and bank configurations

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- CLIENT MANAGEMENT
-- =====================================================

CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    business_name VARCHAR(255),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100) DEFAULT 'India',
    postal_code VARCHAR(20),
    gst_number VARCHAR(20),
    pan_number VARCHAR(20),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    api_key VARCHAR(255) UNIQUE,
    webhook_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

-- =====================================================
-- BANK CONFIGURATION
-- =====================================================

CREATE TABLE banks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bank_code VARCHAR(20) UNIQUE NOT NULL,
    bank_name VARCHAR(255) NOT NULL,
    ifsc_code VARCHAR(20),
    branch_code VARCHAR(20),
    branch_name VARCHAR(255),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100) DEFAULT 'India',
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE bank_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    bank_id UUID NOT NULL REFERENCES banks(id) ON DELETE CASCADE,
    account_number VARCHAR(50) NOT NULL,
    account_holder_name VARCHAR(255) NOT NULL,
    account_type VARCHAR(50) DEFAULT 'savings' CHECK (account_type IN ('savings', 'current', 'business')),
    ifsc_code VARCHAR(20),
    upi_id VARCHAR(100),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(client_id, bank_id, account_number)
);

-- =====================================================
-- QR CODE MANAGEMENT
-- =====================================================

CREATE TABLE qr_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    template_name VARCHAR(255) NOT NULL,
    template_type VARCHAR(50) DEFAULT 'upi' CHECK (template_type IN ('upi', 'bank_transfer', 'payment_link')),
    qr_format VARCHAR(20) DEFAULT 'png' CHECK (qr_format IN ('png', 'svg', 'pdf')),
    size_pixels INTEGER DEFAULT 256,
    foreground_color VARCHAR(7) DEFAULT '#000000',
    background_color VARCHAR(7) DEFAULT '#FFFFFF',
    logo_url VARCHAR(500),
    custom_fields JSONB,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE qr_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    qr_template_id UUID REFERENCES qr_templates(id) ON DELETE SET NULL,
    bank_account_id UUID REFERENCES bank_accounts(id) ON DELETE SET NULL,
    qr_code VARCHAR(255) UNIQUE NOT NULL,
    qr_data TEXT NOT NULL,
    amount DECIMAL(15,2),
    currency VARCHAR(3) DEFAULT 'INR',
    description TEXT,
    expiry_date TIMESTAMP WITH TIME ZONE,
    max_usage_count INTEGER DEFAULT 1,
    current_usage_count INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'expired', 'maxed_out')),
    qr_image_url VARCHAR(500),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

-- =====================================================
-- TRANSACTION TRACKING
-- =====================================================

CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    qr_code_id UUID NOT NULL REFERENCES qr_codes(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    bank_account_id UUID REFERENCES bank_accounts(id) ON DELETE SET NULL,
    transaction_id VARCHAR(100) UNIQUE,
    upi_transaction_id VARCHAR(100),
    payer_name VARCHAR(255),
    payer_phone VARCHAR(20),
    payer_email VARCHAR(255),
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'INR',
    transaction_type VARCHAR(50) DEFAULT 'qr_payment' CHECK (transaction_type IN ('qr_payment', 'refund', 'adjustment')),
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'success', 'failed', 'cancelled', 'refunded')),
    payment_method VARCHAR(50) DEFAULT 'upi' CHECK (payment_method IN ('upi', 'bank_transfer', 'card', 'wallet')),
    bank_reference VARCHAR(100),
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    settlement_date TIMESTAMP WITH TIME ZONE,
    fees DECIMAL(10,2) DEFAULT 0,
    net_amount DECIMAL(15,2),
    remarks TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- USER MANAGEMENT
-- =====================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    role VARCHAR(50) DEFAULT 'user' CHECK (role IN ('super_admin', 'admin', 'user', 'viewer')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'locked')),
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- AUDIT LOGS
-- =====================================================

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100),
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- NOTIFICATIONS
-- =====================================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('transaction', 'qr_expiry', 'system', 'alert')),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP WITH TIME ZONE
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Client indexes
CREATE INDEX idx_clients_status ON clients(status);
CREATE INDEX idx_clients_email ON clients(email);
CREATE INDEX idx_clients_client_code ON clients(client_code);

-- Bank indexes
CREATE INDEX idx_banks_bank_code ON banks(bank_code);
CREATE INDEX idx_banks_status ON banks(status);

-- Bank account indexes
CREATE INDEX idx_bank_accounts_client_id ON bank_accounts(client_id);
CREATE INDEX idx_bank_accounts_bank_id ON bank_accounts(bank_id);
CREATE INDEX idx_bank_accounts_is_primary ON bank_accounts(is_primary);

-- QR code indexes
CREATE INDEX idx_qr_codes_client_id ON qr_codes(client_id);
CREATE INDEX idx_qr_codes_status ON qr_codes(status);
CREATE INDEX idx_qr_codes_expiry_date ON qr_codes(expiry_date);
CREATE INDEX idx_qr_codes_qr_code ON qr_codes(qr_code);

-- Transaction indexes
CREATE INDEX idx_transactions_client_id ON transactions(client_id);
CREATE INDEX idx_transactions_qr_code_id ON transactions(qr_code_id);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_transaction_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_transaction_id ON transactions(transaction_id);

-- User indexes
CREATE INDEX idx_users_client_id ON users(client_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- Audit log indexes
CREATE INDEX idx_audit_logs_client_id ON audit_logs(client_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- Notification indexes
CREATE INDEX idx_notifications_client_id ON notifications(client_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to all tables with updated_at
CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_banks_updated_at BEFORE UPDATE ON banks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_bank_accounts_updated_at BEFORE UPDATE ON bank_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_qr_templates_updated_at BEFORE UPDATE ON qr_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_qr_codes_updated_at BEFORE UPDATE ON qr_codes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- SAMPLE DATA INSERTION
-- =====================================================

-- Insert sample bank
INSERT INTO banks (bank_code, bank_name, ifsc_code, branch_name, city, state) VALUES
('HDFC001', 'HDFC Bank', 'HDFC0001234', 'Main Branch', 'Mumbai', 'Maharashtra'),
('ICICI001', 'ICICI Bank', 'ICIC0005678', 'Central Branch', 'Delhi', 'Delhi'),
('SBI001', 'State Bank of India', 'SBIN0009012', 'Head Office', 'Mumbai', 'Maharashtra');

-- Insert sample client
INSERT INTO clients (client_code, name, business_name, email, phone, city, state) VALUES
('CLIENT001', 'ABC Corporation', 'ABC Corp Pvt Ltd', 'admin@abccorp.com', '+91-9876543210', 'Mumbai', 'Maharashtra'),
('CLIENT002', 'XYZ Enterprises', 'XYZ Enterprises Ltd', 'info@xyzenterprises.com', '+91-9876543211', 'Delhi', 'Delhi');

-- Insert sample bank accounts
INSERT INTO bank_accounts (client_id, bank_id, account_number, account_holder_name, account_type, ifsc_code, is_primary) VALUES
((SELECT id FROM clients WHERE client_code = 'CLIENT001'), (SELECT id FROM banks WHERE bank_code = 'HDFC001'), '1234567890', 'ABC Corporation', 'business', 'HDFC0001234', true),
((SELECT id FROM clients WHERE client_code = 'CLIENT002'), (SELECT id FROM banks WHERE bank_code = 'ICICI001'), '0987654321', 'XYZ Enterprises', 'business', 'ICIC0005678', true);

-- Insert sample user
INSERT INTO users (client_id, username, email, password_hash, first_name, last_name, role) VALUES
((SELECT id FROM clients WHERE client_code = 'CLIENT001'), 'admin_abc', 'admin@abccorp.com', 'hashed_password_here', 'Admin', 'User', 'admin'),
((SELECT id FROM clients WHERE client_code = 'CLIENT002'), 'admin_xyz', 'admin@xyzenterprises.com', 'hashed_password_here', 'Admin', 'User', 'admin');

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- Client summary view
CREATE VIEW client_summary AS
SELECT 
    c.id,
    c.client_code,
    c.name,
    c.business_name,
    c.email,
    c.status,
    COUNT(DISTINCT ba.id) as bank_accounts_count,
    COUNT(DISTINCT qc.id) as qr_codes_count,
    COUNT(DISTINCT t.id) as transactions_count,
    COALESCE(SUM(CASE WHEN t.status = 'success' THEN t.amount ELSE 0 END), 0) as total_success_amount
FROM clients c
LEFT JOIN bank_accounts ba ON c.id = ba.client_id
LEFT JOIN qr_codes qc ON c.id = qc.client_id
LEFT JOIN transactions t ON c.id = t.client_id
GROUP BY c.id, c.client_code, c.name, c.business_name, c.email, c.status;

-- Transaction summary view
CREATE VIEW transaction_summary AS
SELECT 
    t.id,
    t.transaction_id,
    c.client_code,
    c.name as client_name,
    t.amount,
    t.currency,
    t.status,
    t.payment_method,
    t.transaction_date,
    qc.qr_code,
    ba.account_number,
    b.bank_name
FROM transactions t
JOIN clients c ON t.client_id = c.id
LEFT JOIN qr_codes qc ON t.qr_code_id = qc.id
LEFT JOIN bank_accounts ba ON t.bank_account_id = ba.id
LEFT JOIN banks b ON ba.bank_id = b.id;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE clients IS 'Stores client information for the QR collection system';
COMMENT ON TABLE banks IS 'Stores bank information and configurations';
COMMENT ON TABLE bank_accounts IS 'Stores client bank account details linked to banks';
COMMENT ON TABLE qr_templates IS 'Stores QR code templates for different clients';
COMMENT ON TABLE qr_codes IS 'Stores generated QR codes with their metadata';
COMMENT ON TABLE transactions IS 'Stores all transaction records from QR code scans';
COMMENT ON TABLE users IS 'Stores user accounts for client access';
COMMENT ON TABLE audit_logs IS 'Stores audit trail for all system activities';
COMMENT ON TABLE notifications IS 'Stores system notifications for clients and users';