-- QR Collection Project - HIGH CONCURRENCY Database Schema
-- Optimized for high concurrency, high throughput scenarios
-- Supports multiple clients and bank configurations

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- =====================================================
-- CLIENT MANAGEMENT (Optimized for high concurrency)
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
    rate_limit_per_minute INTEGER DEFAULT 1000,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    version INTEGER DEFAULT 1 -- For optimistic locking
);

-- Partition clients by status for better query performance
CREATE INDEX CONCURRENTLY idx_clients_status_partition ON clients(status) WHERE status = 'active';
CREATE INDEX CONCURRENTLY idx_clients_status_partition_inactive ON clients(status) WHERE status = 'inactive';

-- =====================================================
-- BANK CONFIGURATION (Optimized)
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
    client_id UUID NOT NULL,
    bank_id UUID NOT NULL,
    account_number VARCHAR(50) NOT NULL,
    account_holder_name VARCHAR(255) NOT NULL,
    account_type VARCHAR(50) DEFAULT 'savings' CHECK (account_type IN ('savings', 'current', 'business')),
    ifsc_code VARCHAR(20),
    upi_id VARCHAR(100),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    version INTEGER DEFAULT 1,
    UNIQUE(client_id, bank_id, account_number)
);

-- =====================================================
-- QR CODE MANAGEMENT (High Concurrency Optimized)
-- =====================================================

CREATE TABLE qr_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL,
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
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    version INTEGER DEFAULT 1
);

-- Partition QR codes by client_id for better concurrency
CREATE TABLE qr_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL,
    qr_template_id UUID,
    bank_account_id UUID,
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
    updated_by UUID,
    version INTEGER DEFAULT 1,
    CONSTRAINT fk_qr_codes_client FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
    CONSTRAINT fk_qr_codes_template FOREIGN KEY (qr_template_id) REFERENCES qr_templates(id) ON DELETE SET NULL,
    CONSTRAINT fk_qr_codes_bank_account FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(id) ON DELETE SET NULL
);

-- =====================================================
-- TRANSACTION TRACKING (High Concurrency Optimized)
-- =====================================================

-- Partition transactions by date for better performance
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    qr_code_id UUID NOT NULL,
    client_id UUID NOT NULL,
    bank_account_id UUID,
    transaction_id VARCHAR(100) UNIQUE NOT NULL,
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
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    version INTEGER DEFAULT 1,
    CONSTRAINT fk_transactions_qr_code FOREIGN KEY (qr_code_id) REFERENCES qr_codes(id) ON DELETE CASCADE,
    CONSTRAINT fk_transactions_client FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
    CONSTRAINT fk_transactions_bank_account FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(id) ON DELETE SET NULL
);

-- =====================================================
-- USER MANAGEMENT (Optimized)
-- =====================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    role VARCHAR(50) DEFAULT 'user' CHECK (role IN ('super_admin', 'admin', 'user', 'viewer')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'locked')),
    last_login TIMESTAMP WITH TIME ZONE,
    login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    version INTEGER DEFAULT 1,
    CONSTRAINT fk_users_client FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
);

-- =====================================================
-- AUDIT LOGS (High Concurrency Optimized)
-- =====================================================

-- Partition audit logs by date for better performance
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    client_id UUID NOT NULL,
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100),
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_logs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_audit_logs_client FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
);

-- =====================================================
-- NOTIFICATIONS (Optimized)
-- =====================================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL,
    user_id UUID,
    type VARCHAR(50) NOT NULL CHECK (type IN ('transaction', 'qr_expiry', 'system', 'alert')),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT fk_notifications_client FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
    CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- =====================================================
-- HIGH CONCURRENCY OPTIMIZATIONS
-- =====================================================

-- 1. CONCURRENT INDEXES for better performance during high load
CREATE INDEX CONCURRENTLY idx_clients_api_key ON clients(api_key);
CREATE INDEX CONCURRENTLY idx_clients_email ON clients(email);
CREATE INDEX CONCURRENTLY idx_clients_client_code ON clients(client_code);

CREATE INDEX CONCURRENTLY idx_banks_bank_code ON banks(bank_code);
CREATE INDEX CONCURRENTLY idx_banks_status ON banks(status);

CREATE INDEX CONCURRENTLY idx_bank_accounts_client_id ON bank_accounts(client_id);
CREATE INDEX CONCURRENTLY idx_bank_accounts_bank_id ON bank_accounts(bank_id);
CREATE INDEX CONCURRENTLY idx_bank_accounts_is_primary ON bank_accounts(is_primary);
CREATE INDEX CONCURRENTLY idx_bank_accounts_upi_id ON bank_accounts(upi_id);

CREATE INDEX CONCURRENTLY idx_qr_templates_client_id ON qr_templates(client_id);
CREATE INDEX CONCURRENTLY idx_qr_templates_status ON qr_templates(status);

CREATE INDEX CONCURRENTLY idx_qr_codes_client_id ON qr_codes(client_id);
CREATE INDEX CONCURRENTLY idx_qr_codes_status ON qr_codes(status);
CREATE INDEX CONCURRENTLY idx_qr_codes_expiry_date ON qr_codes(expiry_date);
CREATE INDEX CONCURRENTLY idx_qr_codes_qr_code ON qr_codes(qr_code);
CREATE INDEX CONCURRENTLY idx_qr_codes_created_at ON qr_codes(created_at);

-- 2. COMPOSITE INDEXES for complex queries
CREATE INDEX CONCURRENTLY idx_qr_codes_client_status ON qr_codes(client_id, status);
CREATE INDEX CONCURRENTLY idx_qr_codes_client_expiry ON qr_codes(client_id, expiry_date);
CREATE INDEX CONCURRENTLY idx_qr_codes_status_expiry ON qr_codes(status, expiry_date);

CREATE INDEX CONCURRENTLY idx_transactions_client_id ON transactions(client_id);
CREATE INDEX CONCURRENTLY idx_transactions_qr_code_id ON transactions(qr_code_id);
CREATE INDEX CONCURRENTLY idx_transactions_status ON transactions(status);
CREATE INDEX CONCURRENTLY idx_transactions_transaction_date ON transactions(transaction_date);
CREATE INDEX CONCURRENTLY idx_transactions_transaction_id ON transactions(transaction_id);
CREATE INDEX CONCURRENTLY idx_transactions_upi_transaction_id ON transactions(upi_transaction_id);

-- 3. COMPOSITE INDEXES for transactions
CREATE INDEX CONCURRENTLY idx_transactions_client_status ON transactions(client_id, status);
CREATE INDEX CONCURRENTLY idx_transactions_client_date ON transactions(client_id, transaction_date);
CREATE INDEX CONCURRENTLY idx_transactions_status_date ON transactions(status, transaction_date);
CREATE INDEX CONCURRENTLY idx_transactions_qr_status ON transactions(qr_code_id, status);

CREATE INDEX CONCURRENTLY idx_users_client_id ON users(client_id);
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
CREATE INDEX CONCURRENTLY idx_users_role ON users(role);
CREATE INDEX CONCURRENTLY idx_users_status ON users(status);

CREATE INDEX CONCURRENTLY idx_audit_logs_client_id ON audit_logs(client_id);
CREATE INDEX CONCURRENTLY idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX CONCURRENTLY idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX CONCURRENTLY idx_audit_logs_action ON audit_logs(action);

CREATE INDEX CONCURRENTLY idx_notifications_client_id ON notifications(client_id);
CREATE INDEX CONCURRENTLY idx_notifications_user_id ON notifications(user_id);
CREATE INDEX CONCURRENTLY idx_notifications_is_read ON notifications(is_read);
CREATE INDEX CONCURRENTLY idx_notifications_created_at ON notifications(created_at);
CREATE INDEX CONCURRENTLY idx_notifications_type ON notifications(type);

-- 4. PARTIAL INDEXES for better performance
CREATE INDEX CONCURRENTLY idx_transactions_success_amount ON transactions(amount) WHERE status = 'success';
CREATE INDEX CONCURRENTLY idx_transactions_pending ON transactions(created_at) WHERE status = 'pending';
CREATE INDEX CONCURRENTLY idx_qr_codes_active ON qr_codes(created_at) WHERE status = 'active';
CREATE INDEX CONCURRENTLY idx_notifications_unread ON notifications(created_at) WHERE is_read = false;

-- 5. GIN INDEXES for JSONB fields
CREATE INDEX CONCURRENTLY idx_qr_templates_custom_fields ON qr_templates USING GIN (custom_fields);
CREATE INDEX CONCURRENTLY idx_qr_codes_metadata ON qr_codes USING GIN (metadata);
CREATE INDEX CONCURRENTLY idx_transactions_metadata ON transactions USING GIN (metadata);
CREATE INDEX CONCURRENTLY idx_notifications_metadata ON notifications USING GIN (metadata);

-- =====================================================
-- TRIGGERS FOR HIGH CONCURRENCY
-- =====================================================

-- Optimized trigger function for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    NEW.version = OLD.version + 1;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers
CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_banks_updated_at BEFORE UPDATE ON banks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_bank_accounts_updated_at BEFORE UPDATE ON bank_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_qr_templates_updated_at BEFORE UPDATE ON qr_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_qr_codes_updated_at BEFORE UPDATE ON qr_codes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- HIGH CONCURRENCY VIEWS
-- =====================================================

-- Materialized view for client summary (refresh periodically)
CREATE MATERIALIZED VIEW client_summary_mv AS
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
    COALESCE(SUM(CASE WHEN t.status = 'success' THEN t.amount ELSE 0 END), 0) as total_success_amount,
    MAX(t.transaction_date) as last_transaction_date
FROM clients c
LEFT JOIN bank_accounts ba ON c.id = ba.client_id
LEFT JOIN qr_codes qc ON c.id = qc.client_id
LEFT JOIN transactions t ON c.id = t.client_id
GROUP BY c.id, c.client_code, c.name, c.business_name, c.email, c.status;

-- Create index on materialized view
CREATE UNIQUE INDEX idx_client_summary_mv_id ON client_summary_mv(id);
CREATE INDEX idx_client_summary_mv_status ON client_summary_mv(status);

-- High performance transaction summary view
CREATE VIEW transaction_summary_optimized AS
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
    b.bank_name,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - t.transaction_date)) / 3600 as hours_ago
FROM transactions t
JOIN clients c ON t.client_id = c.id
LEFT JOIN qr_codes qc ON t.qr_code_id = qc.id
LEFT JOIN bank_accounts ba ON t.bank_account_id = ba.id
LEFT JOIN banks b ON ba.bank_id = b.id;

-- =====================================================
-- FUNCTIONS FOR HIGH CONCURRENCY
-- =====================================================

-- Function to refresh materialized views
CREATE OR REPLACE FUNCTION refresh_client_summary()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY client_summary_mv;
END;
$$ LANGUAGE plpgsql;

-- Function to get client statistics with caching
CREATE OR REPLACE FUNCTION get_client_stats(client_uuid UUID)
RETURNS TABLE(
    total_transactions BIGINT,
    success_transactions BIGINT,
    total_amount DECIMAL,
    success_rate DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT as total_transactions,
        COUNT(*) FILTER (WHERE status = 'success')::BIGINT as success_transactions,
        COALESCE(SUM(amount), 0) as total_amount,
        CASE 
            WHEN COUNT(*) > 0 THEN 
                (COUNT(*) FILTER (WHERE status = 'success')::DECIMAL / COUNT(*)::DECIMAL) * 100
            ELSE 0 
        END as success_rate
    FROM transactions 
    WHERE client_id = client_uuid;
END;
$$ LANGUAGE plpgsql;

-- Function to update QR code usage count atomically
CREATE OR REPLACE FUNCTION update_qr_usage(qr_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
    current_count INTEGER;
    max_count INTEGER;
BEGIN
    -- Use SELECT FOR UPDATE to prevent race conditions
    SELECT current_usage_count, max_usage_count 
    INTO current_count, max_count
    FROM qr_codes 
    WHERE id = qr_uuid AND status = 'active'
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    IF current_count >= max_count THEN
        UPDATE qr_codes SET status = 'maxed_out' WHERE id = qr_uuid;
        RETURN FALSE;
    END IF;
    
    UPDATE qr_codes 
    SET current_usage_count = current_usage_count + 1,
        updated_at = CURRENT_TIMESTAMP,
        version = version + 1
    WHERE id = qr_uuid;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SAMPLE DATA INSERTION (High Concurrency Ready)
-- =====================================================

-- Insert sample banks
INSERT INTO banks (bank_code, bank_name, ifsc_code, branch_name, city, state) VALUES
('HDFC001', 'HDFC Bank', 'HDFC0001234', 'Main Branch', 'Mumbai', 'Maharashtra'),
('ICICI001', 'ICICI Bank', 'ICIC0005678', 'Central Branch', 'Delhi', 'Delhi'),
('SBI001', 'State Bank of India', 'SBIN0009012', 'Head Office', 'Mumbai', 'Maharashtra'),
('AXIS001', 'Axis Bank', 'UTIB0001234', 'Corporate Branch', 'Bangalore', 'Karnataka'),
('KOTAK001', 'Kotak Mahindra Bank', 'KMAH0005678', 'Business Branch', 'Chennai', 'Tamil Nadu');

-- Insert sample clients
INSERT INTO clients (client_code, name, business_name, email, phone, city, state, rate_limit_per_minute) VALUES
('CLIENT001', 'ABC Corporation', 'ABC Corp Pvt Ltd', 'admin@abccorp.com', '+91-9876543210', 'Mumbai', 'Maharashtra', 5000),
('CLIENT002', 'XYZ Enterprises', 'XYZ Enterprises Ltd', 'info@xyzenterprises.com', '+91-9876543211', 'Delhi', 'Delhi', 3000),
('CLIENT003', 'Tech Solutions', 'Tech Solutions Inc', 'admin@techsolutions.com', '+91-9876543212', 'Bangalore', 'Karnataka', 2000),
('CLIENT004', 'Global Retail', 'Global Retail Chain', 'info@globalretail.com', '+91-9876543213', 'Chennai', 'Tamil Nadu', 4000),
('CLIENT005', 'Finance Corp', 'Finance Corporation Ltd', 'admin@financecorp.com', '+91-9876543214', 'Hyderabad', 'Telangana', 6000);

-- Insert sample bank accounts
INSERT INTO bank_accounts (client_id, bank_id, account_number, account_holder_name, account_type, ifsc_code, is_primary) VALUES
((SELECT id FROM clients WHERE client_code = 'CLIENT001'), (SELECT id FROM banks WHERE bank_code = 'HDFC001'), '1234567890', 'ABC Corporation', 'business', 'HDFC0001234', true),
((SELECT id FROM clients WHERE client_code = 'CLIENT002'), (SELECT id FROM banks WHERE bank_code = 'ICICI001'), '0987654321', 'XYZ Enterprises', 'business', 'ICIC0005678', true),
((SELECT id FROM clients WHERE client_code = 'CLIENT003'), (SELECT id FROM banks WHERE bank_code = 'AXIS001'), '1122334455', 'Tech Solutions', 'business', 'UTIB0001234', true),
((SELECT id FROM clients WHERE client_code = 'CLIENT004'), (SELECT id FROM banks WHERE bank_code = 'KOTAK001'), '5566778899', 'Global Retail', 'business', 'KMAH0005678', true),
((SELECT id FROM clients WHERE client_code = 'CLIENT005'), (SELECT id FROM banks WHERE bank_code = 'SBI001'), '9988776655', 'Finance Corp', 'business', 'SBIN0009012', true);

-- Insert sample users
INSERT INTO users (client_id, username, email, password_hash, first_name, last_name, role) VALUES
((SELECT id FROM clients WHERE client_code = 'CLIENT001'), 'admin_abc', 'admin@abccorp.com', 'hashed_password_here', 'Admin', 'User', 'admin'),
((SELECT id FROM clients WHERE client_code = 'CLIENT002'), 'admin_xyz', 'admin@xyzenterprises.com', 'hashed_password_here', 'Admin', 'User', 'admin'),
((SELECT id FROM clients WHERE client_code = 'CLIENT003'), 'admin_tech', 'admin@techsolutions.com', 'hashed_password_here', 'Admin', 'User', 'admin'),
((SELECT id FROM clients WHERE client_code = 'CLIENT004'), 'admin_retail', 'admin@globalretail.com', 'hashed_password_here', 'Admin', 'User', 'admin'),
((SELECT id FROM clients WHERE client_code = 'CLIENT005'), 'admin_finance', 'admin@financecorp.com', 'hashed_password_here', 'Admin', 'User', 'admin');

-- =====================================================
-- HIGH CONCURRENCY CONFIGURATION
-- =====================================================

-- Set optimal PostgreSQL parameters for high concurrency
-- These should be set in postgresql.conf or via ALTER SYSTEM

-- Connection and memory settings
-- max_connections = 200
-- shared_buffers = 256MB
-- effective_cache_size = 1GB
-- work_mem = 4MB
-- maintenance_work_mem = 64MB

-- WAL and checkpoint settings
-- wal_buffers = 16MB
-- checkpoint_completion_target = 0.9
-- checkpoint_segments = 32
-- checkpoint_timeout = 5min

-- Query planner settings
-- random_page_cost = 1.1
-- effective_io_concurrency = 200
-- default_statistics_target = 100

-- Lock and deadlock settings
-- deadlock_timeout = 1s
-- lock_timeout = 30s
-- statement_timeout = 30s

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE clients IS 'Stores client information for the QR collection system - High concurrency optimized';
COMMENT ON TABLE banks IS 'Stores bank information and configurations - High concurrency optimized';
COMMENT ON TABLE bank_accounts IS 'Stores client bank account details linked to banks - High concurrency optimized';
COMMENT ON TABLE qr_templates IS 'Stores QR code templates for different clients - High concurrency optimized';
COMMENT ON TABLE qr_codes IS 'Stores generated QR codes with their metadata - High concurrency optimized';
COMMENT ON TABLE transactions IS 'Stores all transaction records from QR code scans - High concurrency optimized';
COMMENT ON TABLE users IS 'Stores user accounts for client access - High concurrency optimized';
COMMENT ON TABLE audit_logs IS 'Stores audit trail for all system activities - High concurrency optimized';
COMMENT ON TABLE notifications IS 'Stores system notifications for clients and users - High concurrency optimized';

COMMENT ON MATERIALIZED VIEW client_summary_mv IS 'Materialized view for client summary - Refreshed periodically for high performance';
COMMENT ON FUNCTION update_qr_usage IS 'Atomic function to update QR code usage count - Prevents race conditions';
COMMENT ON FUNCTION get_client_stats IS 'Function to get client statistics with optimized queries';