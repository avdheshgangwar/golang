package main

import (
	"database/sql/driver"
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// =====================================================
// BASE STRUCTS
// =====================================================

// JSONB type for PostgreSQL JSONB fields
type JSONB map[string]interface{}

func (j JSONB) Value() (driver.Value, error) {
	if j == nil {
		return nil, nil
	}
	return json.Marshal(j)
}

func (j *JSONB) Scan(value interface{}) error {
	if value == nil {
		*j = nil
		return nil
	}
	
	switch v := value.(type) {
	case []byte:
		return json.Unmarshal(v, j)
	case string:
		return json.Unmarshal([]byte(v), j)
	default:
		return nil
	}
}

// =====================================================
// CLIENT MANAGEMENT
// =====================================================

type Client struct {
	ID          uuid.UUID `json:"id" db:"id"`
	ClientCode  string    `json:"client_code" db:"client_code"`
	Name        string    `json:"name" db:"name"`
	BusinessName string   `json:"business_name" db:"business_name"`
	Email       string    `json:"email" db:"email"`
	Phone       string    `json:"phone" db:"phone"`
	Address     string    `json:"address" db:"address"`
	City        string    `json:"city" db:"city"`
	State       string    `json:"state" db:"state"`
	Country     string    `json:"country" db:"country"`
	PostalCode  string    `json:"postal_code" db:"postal_code"`
	GSTNumber   string    `json:"gst_number" db:"gst_number"`
	PANNumber   string    `json:"pan_number" db:"pan_number"`
	Status      string    `json:"status" db:"status"`
	APIKey      string    `json:"api_key" db:"api_key"`
	WebhookURL  string    `json:"webhook_url" db:"webhook_url"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
	CreatedBy   *uuid.UUID `json:"created_by" db:"created_by"`
	UpdatedBy   *uuid.UUID `json:"updated_by" db:"updated_by"`
}

// =====================================================
// BANK CONFIGURATION
// =====================================================

type Bank struct {
	ID          uuid.UUID `json:"id" db:"id"`
	BankCode    string    `json:"bank_code" db:"bank_code"`
	BankName    string    `json:"bank_name" db:"bank_name"`
	IFSCCode    string    `json:"ifsc_code" db:"ifsc_code"`
	BranchCode  string    `json:"branch_code" db:"branch_code"`
	BranchName  string    `json:"branch_name" db:"branch_name"`
	Address     string    `json:"address" db:"address"`
	City        string    `json:"city" db:"city"`
	State       string    `json:"state" db:"state"`
	Country     string    `json:"country" db:"country"`
	Status      string    `json:"status" db:"status"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}

type BankAccount struct {
	ID                uuid.UUID `json:"id" db:"id"`
	ClientID          uuid.UUID `json:"client_id" db:"client_id"`
	BankID            uuid.UUID `json:"bank_id" db:"bank_id"`
	AccountNumber     string    `json:"account_number" db:"account_number"`
	AccountHolderName string    `json:"account_holder_name" db:"account_holder_name"`
	AccountType       string    `json:"account_type" db:"account_type"`
	IFSCCode          string    `json:"ifsc_code" db:"ifsc_code"`
	UPIID             string    `json:"upi_id" db:"upi_id"`
	Status            string    `json:"status" db:"status"`
	IsPrimary         bool      `json:"is_primary" db:"is_primary"`
	CreatedAt         time.Time `json:"created_at" db:"created_at"`
	UpdatedAt         time.Time `json:"updated_at" db:"updated_at"`
	
	// Relations
	Client *Client `json:"client,omitempty" db:"-"`
	Bank   *Bank   `json:"bank,omitempty" db:"-"`
}

// =====================================================
// QR CODE MANAGEMENT
// =====================================================

type QRTemplate struct {
	ID              uuid.UUID `json:"id" db:"id"`
	ClientID        uuid.UUID `json:"client_id" db:"client_id"`
	TemplateName    string    `json:"template_name" db:"template_name"`
	TemplateType    string    `json:"template_type" db:"template_type"`
	QRFormat        string    `json:"qr_format" db:"qr_format"`
	SizePixels      int       `json:"size_pixels" db:"size_pixels"`
	ForegroundColor string    `json:"foreground_color" db:"foreground_color"`
	BackgroundColor string    `json:"background_color" db:"background_color"`
	LogoURL         string    `json:"logo_url" db:"logo_url"`
	CustomFields    JSONB     `json:"custom_fields" db:"custom_fields"`
	Status          string    `json:"status" db:"status"`
	CreatedAt       time.Time `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time `json:"updated_at" db:"updated_at"`
	
	// Relations
	Client *Client `json:"client,omitempty" db:"-"`
}

type QRCode struct {
	ID                uuid.UUID  `json:"id" db:"id"`
	ClientID          uuid.UUID  `json:"client_id" db:"client_id"`
	QRTemplateID      *uuid.UUID `json:"qr_template_id" db:"qr_template_id"`
	BankAccountID     *uuid.UUID `json:"bank_account_id" db:"bank_account_id"`
	QRCode            string     `json:"qr_code" db:"qr_code"`
	QRData            string     `json:"qr_data" db:"qr_data"`
	Amount            *float64   `json:"amount" db:"amount"`
	Currency          string     `json:"currency" db:"currency"`
	Description       string     `json:"description" db:"description"`
	ExpiryDate        *time.Time `json:"expiry_date" db:"expiry_date"`
	MaxUsageCount     int        `json:"max_usage_count" db:"max_usage_count"`
	CurrentUsageCount int        `json:"current_usage_count" db:"current_usage_count"`
	Status            string     `json:"status" db:"status"`
	QRImageURL        string     `json:"qr_image_url" db:"qr_image_url"`
	Metadata          JSONB      `json:"metadata" db:"metadata"`
	CreatedAt         time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt         time.Time  `json:"updated_at" db:"updated_at"`
	CreatedBy         *uuid.UUID `json:"created_by" db:"created_by"`
	UpdatedBy         *uuid.UUID `json:"updated_by" db:"updated_by"`
	
	// Relations
	Client       *Client       `json:"client,omitempty" db:"-"`
	QRTemplate  *QRTemplate   `json:"qr_template,omitempty" db:"-"`
	BankAccount *BankAccount  `json:"bank_account,omitempty" db:"-"`
}

// =====================================================
// TRANSACTION TRACKING
// =====================================================

type Transaction struct {
	ID                uuid.UUID  `json:"id" db:"id"`
	QRCodeID          uuid.UUID  `json:"qr_code_id" db:"qr_code_id"`
	ClientID          uuid.UUID  `json:"client_id" db:"client_id"`
	BankAccountID     *uuid.UUID `json:"bank_account_id" db:"bank_account_id"`
	TransactionID     string     `json:"transaction_id" db:"transaction_id"`
	UPITransactionID  string     `json:"upi_transaction_id" db:"upi_transaction_id"`
	PayerName         string     `json:"payer_name" db:"payer_name"`
	PayerPhone        string     `json:"payer_phone" db:"payer_phone"`
	PayerEmail        string     `json:"payer_email" db:"payer_email"`
	Amount            float64    `json:"amount" db:"amount"`
	Currency          string     `json:"currency" db:"currency"`
	TransactionType   string     `json:"transaction_type" db:"transaction_type"`
	Status            string     `json:"status" db:"status"`
	PaymentMethod     string     `json:"payment_method" db:"payment_method"`
	BankReference     string     `json:"bank_reference" db:"bank_reference"`
	TransactionDate   time.Time  `json:"transaction_date" db:"transaction_date"`
	SettlementDate    *time.Time `json:"settlement_date" db:"settlement_date"`
	Fees              float64    `json:"fees" db:"fees"`
	NetAmount         *float64   `json:"net_amount" db:"net_amount"`
	Remarks           string     `json:"remarks" db:"remarks"`
	Metadata          JSONB      `json:"metadata" db:"metadata"`
	CreatedAt         time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt         time.Time  `json:"updated_at" db:"updated_at"`
	
	// Relations
	QRCode      *QRCode      `json:"qr_code,omitempty" db:"-"`
	Client      *Client      `json:"client,omitempty" db:"-"`
	BankAccount *BankAccount `json:"bank_account,omitempty" db:"-"`
}

// =====================================================
// USER MANAGEMENT
// =====================================================

type User struct {
	ID           uuid.UUID  `json:"id" db:"id"`
	ClientID     *uuid.UUID `json:"client_id" db:"client_id"`
	Username     string     `json:"username" db:"username"`
	Email        string     `json:"email" db:"email"`
	PasswordHash string     `json:"-" db:"password_hash"` // Never expose in JSON
	FirstName    string     `json:"first_name" db:"first_name"`
	LastName     string     `json:"last_name" db:"last_name"`
	Phone        string     `json:"phone" db:"phone"`
	Role         string     `json:"role" db:"role"`
	Status       string     `json:"status" db:"status"`
	LastLogin    *time.Time `json:"last_login" db:"last_login"`
	CreatedAt    time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at" db:"updated_at"`
	
	// Relations
	Client *Client `json:"client,omitempty" db:"-"`
}

// =====================================================
// AUDIT LOGS
// =====================================================

type AuditLog struct {
	ID        uuid.UUID  `json:"id" db:"id"`
	UserID    *uuid.UUID `json:"user_id" db:"user_id"`
	ClientID  uuid.UUID  `json:"client_id" db:"client_id"`
	Action    string     `json:"action" db:"action"`
	TableName string     `json:"table_name" db:"table_name"`
	RecordID  *uuid.UUID `json:"record_id" db:"record_id"`
	OldValues JSONB      `json:"old_values" db:"old_values"`
	NewValues JSONB      `json:"new_values" db:"new_values"`
	IPAddress string     `json:"ip_address" db:"ip_address"`
	UserAgent string     `json:"user_agent" db:"user_agent"`
	CreatedAt time.Time  `json:"created_at" db:"created_at"`
	
	// Relations
	User   *User   `json:"user,omitempty" db:"-"`
	Client *Client `json:"client,omitempty" db:"-"`
}

// =====================================================
// NOTIFICATIONS
// =====================================================

type Notification struct {
	ID        uuid.UUID  `json:"id" db:"id"`
	ClientID  uuid.UUID  `json:"client_id" db:"client_id"`
	UserID    *uuid.UUID `json:"user_id" db:"user_id"`
	Type      string     `json:"type" db:"type"`
	Title     string     `json:"title" db:"title"`
	Message   string     `json:"message" db:"message"`
	IsRead    bool       `json:"is_read" db:"is_read"`
	Priority  string     `json:"priority" db:"priority"`
	Metadata  JSONB      `json:"metadata" db:"metadata"`
	CreatedAt time.Time  `json:"created_at" db:"created_at"`
	ReadAt    *time.Time `json:"read_at" db:"read_at"`
	
	// Relations
	Client *Client `json:"client,omitempty" db:"-"`
	User   *User   `json:"user,omitempty" db:"-"`
}

// =====================================================
// SUMMARY VIEWS
// =====================================================

type ClientSummary struct {
	ID                    uuid.UUID `json:"id" db:"id"`
	ClientCode            string    `json:"client_code" db:"client_code"`
	Name                  string    `json:"name" db:"name"`
	BusinessName          string    `json:"business_name" db:"business_name"`
	Email                 string    `json:"email" db:"email"`
	Status                string    `json:"status" db:"status"`
	BankAccountsCount     int       `json:"bank_accounts_count" db:"bank_accounts_count"`
	QRCodesCount          int       `json:"qr_codes_count" db:"qr_codes_count"`
	TransactionsCount     int       `json:"transactions_count" db:"transactions_count"`
	TotalSuccessAmount    float64   `json:"total_success_amount" db:"total_success_amount"`
}

type TransactionSummary struct {
	ID             uuid.UUID `json:"id" db:"id"`
	TransactionID  string    `json:"transaction_id" db:"transaction_id"`
	ClientCode     string    `json:"client_code" db:"client_code"`
	ClientName     string    `json:"client_name" db:"client_name"`
	Amount         float64   `json:"amount" db:"amount"`
	Currency       string    `json:"currency" db:"currency"`
	Status         string    `json:"status" db:"status"`
	PaymentMethod  string    `json:"payment_method" db:"payment_method"`
	TransactionDate time.Time `json:"transaction_date" db:"transaction_date"`
	QRCode         string    `json:"qr_code" db:"qr_code"`
	AccountNumber  string    `json:"account_number" db:"account_number"`
	BankName       string    `json:"bank_name" db:"bank_name"`
}

// =====================================================
// CONSTANTS
// =====================================================

const (
	// Client Status
	ClientStatusActive     = "active"
	ClientStatusInactive   = "inactive"
	ClientStatusSuspended  = "suspended"
	
	// Bank Status
	BankStatusActive   = "active"
	BankStatusInactive = "inactive"
	
	// Account Types
	AccountTypeSavings  = "savings"
	AccountTypeCurrent  = "current"
	AccountTypeBusiness = "business"
	
	// QR Template Types
	QRTemplateTypeUPI          = "upi"
	QRTemplateTypeBankTransfer = "bank_transfer"
	QRTemplateTypePaymentLink  = "payment_link"
	
	// QR Formats
	QRFormatPNG = "png"
	QRFormatSVG = "svg"
	QRFormatPDF = "pdf"
	
	// QR Code Status
	QRCodeStatusActive    = "active"
	QRCodeStatusInactive  = "inactive"
	QRCodeStatusExpired   = "expired"
	QRCodeStatusMaxedOut  = "maxed_out"
	
	// Transaction Types
	TransactionTypeQRPayment = "qr_payment"
	TransactionTypeRefund    = "refund"
	TransactionTypeAdjustment = "adjustment"
	
	// Transaction Status
	TransactionStatusPending   = "pending"
	TransactionStatusSuccess   = "success"
	TransactionStatusFailed    = "failed"
	TransactionStatusCancelled = "cancelled"
	TransactionStatusRefunded  = "refunded"
	
	// Payment Methods
	PaymentMethodUPI          = "upi"
	PaymentMethodBankTransfer = "bank_transfer"
	PaymentMethodCard         = "card"
	PaymentMethodWallet       = "wallet"
	
	// User Roles
	UserRoleSuperAdmin = "super_admin"
	UserRoleAdmin      = "admin"
	UserRoleUser       = "user"
	UserRoleViewer     = "viewer"
	
	// User Status
	UserStatusActive   = "active"
	UserStatusInactive = "inactive"
	UserStatusLocked   = "locked"
	
	// Notification Types
	NotificationTypeTransaction = "transaction"
	NotificationTypeQRExpiry   = "qr_expiry"
	NotificationTypeSystem     = "system"
	NotificationTypeAlert      = "alert"
	
	// Notification Priority
	NotificationPriorityLow    = "low"
	NotificationPriorityNormal = "normal"
	NotificationPriorityHigh   = "high"
	NotificationPriorityUrgent = "urgent"
)