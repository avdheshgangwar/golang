# QR Collection Project - PostgreSQL Database Schema

A comprehensive PostgreSQL database schema for a QR collection system that handles multiple clients and bank configurations.

## 🏗️ Database Architecture

### Core Tables

#### 1. **Client Management**
- **`clients`** - Stores client information, business details, and API configurations
- **`users`** - User accounts for client access with role-based permissions

#### 2. **Bank Configuration**
- **`banks`** - Bank information and branch details
- **`bank_accounts`** - Client bank account details linked to banks

#### 3. **QR Code Management**
- **`qr_templates`** - Reusable QR code templates for clients
- **`qr_codes`** - Generated QR codes with metadata and usage tracking

#### 4. **Transaction Tracking**
- **`transactions`** - Complete transaction records from QR code scans

#### 5. **Audit & Monitoring**
- **`audit_logs`** - Comprehensive audit trail for all system activities
- **`notifications`** - System notifications for clients and users

## 🚀 Quick Start

### Prerequisites
- PostgreSQL 12+ 
- Go 1.18+
- Docker (optional)

### 1. Database Setup

#### Option A: Direct PostgreSQL
```bash
# Create database
createdb qr_collection

# Run schema
psql -d qr_collection -f database_schema.sql
```

#### Option B: Docker
```bash
# Start PostgreSQL container
docker run --name qr-postgres \
  -e POSTGRES_PASSWORD=your_password \
  -e POSTGRES_DB=qr_collection \
  -p 5432:5432 \
  -d postgres:14

# Run schema
psql -h localhost -U postgres -d qr_collection -f database_schema.sql
```

### 2. Environment Configuration
```bash
# Copy environment file
cp .env.example .env

# Edit with your database credentials
nano .env
```

### 3. Install Dependencies
```bash
go mod tidy
```

### 4. Run Application
```bash
go run .
```

## 📊 Database Schema Details

### Client Management

```sql
CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    business_name VARCHAR(255),
    email VARCHAR(255) UNIQUE NOT NULL,
    -- ... more fields
);
```

**Key Features:**
- Unique client codes for easy identification
- Business registration details (GST, PAN)
- API key management for integrations
- Webhook URL for real-time notifications
- Multi-status support (active/inactive/suspended)

### Bank Configuration

```sql
CREATE TABLE banks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bank_code VARCHAR(20) UNIQUE NOT NULL,
    bank_name VARCHAR(255) NOT NULL,
    ifsc_code VARCHAR(20),
    -- ... more fields
);
```

**Key Features:**
- Bank and branch information
- IFSC code support for Indian banks
- Status management for active/inactive banks

### QR Code Management

```sql
CREATE TABLE qr_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id),
    qr_data TEXT NOT NULL,
    amount DECIMAL(15,2),
    expiry_date TIMESTAMP WITH TIME ZONE,
    max_usage_count INTEGER DEFAULT 1,
    -- ... more fields
);
```

**Key Features:**
- Dynamic QR code generation
- Amount specification (fixed or variable)
- Expiry date management
- Usage count limits
- Template-based generation

### Transaction Tracking

```sql
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    qr_code_id UUID NOT NULL REFERENCES qr_codes(id),
    amount DECIMAL(15,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    payment_method VARCHAR(50) DEFAULT 'upi',
    -- ... more fields
);
```

**Key Features:**
- Complete transaction lifecycle tracking
- Multiple payment method support
- UPI transaction ID mapping
- Settlement date tracking
- Fee and net amount calculations

## 🔐 Security Features

### User Management
- Role-based access control (super_admin, admin, user, viewer)
- Password hashing (never stored in plain text)
- Account status management (active/inactive/locked)
- Last login tracking

### Audit Logging
- Complete audit trail for all operations
- IP address and user agent tracking
- Before/after value comparison
- User action tracking

### API Security
- Client-specific API keys
- Webhook signature verification
- Rate limiting support (implement in application layer)

## 📈 Performance Optimizations

### Indexes
- Primary key indexes on all tables
- Foreign key indexes for joins
- Status-based indexes for filtering
- Date-based indexes for time-series queries

### Views
- **`client_summary`** - Client overview with counts and totals
- **`transaction_summary`** - Transaction details with related information

### Connection Pooling
- Configurable connection pool settings
- Connection health monitoring
- Automatic connection cleanup

## 🔄 Data Flow

```
Client Request → QR Generation → QR Code Storage → Transaction Tracking → Settlement
     ↓              ↓              ↓                ↓              ↓
  Client Auth   Template Use   Usage Limits    Status Updates   Bank Sync
```

## 📋 Sample Queries

### Get Client Summary
```sql
SELECT * FROM client_summary WHERE client_code = 'CLIENT001';
```

### Get Recent Transactions
```sql
SELECT * FROM transaction_summary 
WHERE client_code = 'CLIENT001' 
ORDER BY transaction_date DESC 
LIMIT 10;
```

### Get Active QR Codes
```sql
SELECT qc.*, c.name as client_name, ba.account_number
FROM qr_codes qc
JOIN clients c ON qc.client_id = c.id
LEFT JOIN bank_accounts ba ON qc.bank_account_id = ba.id
WHERE qc.status = 'active' AND qc.expiry_date > NOW();
```

## 🛠️ Integration Points

### Webhook Support
- Real-time transaction notifications
- Client-specific webhook URLs
- Configurable notification types

### API Integration
- RESTful API endpoints (implement in application layer)
- Client authentication via API keys
- Rate limiting and throttling

### Bank Integration
- UPI transaction tracking
- Bank reference mapping
- Settlement date synchronization

## 📝 Database Maintenance

### Regular Tasks
- Monitor connection pool statistics
- Check for expired QR codes
- Archive old transaction data
- Update audit log retention

### Backup Strategy
```bash
# Daily backup
pg_dump qr_collection > backup_$(date +%Y%m%d).sql

# Restore
psql qr_collection < backup_20231201.sql
```

## 🚨 Monitoring & Alerts

### Key Metrics
- Database connection pool status
- Transaction success rates
- QR code generation volume
- Client activity levels

### Alert Conditions
- High transaction failure rates
- Database connection issues
- QR code expiry warnings
- Unusual transaction patterns

## 🔧 Troubleshooting

### Common Issues

#### Connection Problems
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Test connection
psql -h localhost -U postgres -d qr_collection
```

#### Performance Issues
```sql
-- Check slow queries
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;
```

#### Schema Issues
```sql
-- Verify table structure
\d+ clients
\d+ qr_codes
\d+ transactions
```

## 📚 Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Go Database/SQL Tutorial](https://golang.org/doc/database/)
- [UUID Extension](https://www.postgresql.org/docs/current/uuid-ossp.html)
- [JSONB Operations](https://www.postgresql.org/docs/current/functions-json.html)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review the database logs
- Contact the development team

---

**Note:** This schema is designed for production use but should be thoroughly tested in your specific environment before deployment.