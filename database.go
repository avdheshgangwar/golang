package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"time"

	_ "github.com/lib/pq"
)

// DatabaseConfig holds database configuration
type DatabaseConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	DBName   string
	SSLMode  string
}

// Database represents the database connection and operations
type Database struct {
	*sql.DB
}

// NewDatabaseConfig creates a new database configuration from environment variables
func NewDatabaseConfig() *DatabaseConfig {
	return &DatabaseConfig{
		Host:     getEnv("DB_HOST", "localhost"),
		Port:     getEnv("DB_PORT", "5432"),
		User:     getEnv("DB_USER", "postgres"),
		Password: getEnv("DB_PASSWORD", ""),
		DBName:   getEnv("DB_NAME", "qr_collection"),
		SSLMode:  getEnv("DB_SSLMODE", "disable"),
	}
}

// Connect establishes a connection to the PostgreSQL database
func (config *DatabaseConfig) Connect() (*Database, error) {
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		config.Host, config.Port, config.User, config.Password, config.DBName, config.SSLMode)

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open database connection: %w", err)
	}

	// Test the connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	// Configure connection pool
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(25)
	db.SetConnMaxLifetime(5 * time.Minute)

	log.Println("Successfully connected to PostgreSQL database")
	return &Database{db}, nil
}

// Close closes the database connection
func (db *Database) Close() error {
	return db.DB.Close()
}

// HealthCheck performs a health check on the database
func (db *Database) HealthCheck() error {
	return db.Ping()
}

// GetStats returns database statistics
func (db *Database) GetStats() sql.DBStats {
	return db.Stats()
}

// =====================================================
// HELPER FUNCTIONS
// =====================================================

// getEnv gets an environment variable or returns a default value
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// =====================================================
// DATABASE INITIALIZATION
// =====================================================

// InitDatabase initializes the database with the schema
func (db *Database) InitDatabase() error {
	// Read the schema file
	schemaSQL, err := os.ReadFile("database_schema.sql")
	if err != nil {
		return fmt.Errorf("failed to read schema file: %w", err)
	}

	// Execute the schema
	_, err = db.Exec(string(schemaSQL))
	if err != nil {
		return fmt.Errorf("failed to execute schema: %w", err)
	}

	log.Println("Database schema initialized successfully")
	return nil
}

// =====================================================
// TRANSACTION HELPERS
// =====================================================

// WithTransaction executes a function within a database transaction
func (db *Database) WithTransaction(fn func(*sql.Tx) error) error {
	tx, err := db.Begin()
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}

	defer func() {
		if p := recover(); p != nil {
			// A panic occurred, rollback and re-panic
			tx.Rollback()
			panic(p)
		} else if err != nil {
			// Something went wrong, rollback
			tx.Rollback()
		} else {
			// All good, commit
			err = tx.Commit()
		}
	}()

	err = fn(tx)
	return err
}

// =====================================================
// CONNECTION POOL MONITORING
// =====================================================

// MonitorConnectionPool starts monitoring the database connection pool
func (db *Database) MonitorConnectionPool() {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for range ticker.C {
		stats := db.GetStats()
		log.Printf("DB Stats - Open: %d, InUse: %d, Idle: %d, WaitCount: %d, WaitDuration: %v",
			stats.OpenConnections, stats.InUse, stats.Idle, stats.WaitCount, stats.WaitDuration)
	}
}

// =====================================================
// ENVIRONMENT VARIABLES DOCUMENTATION
// =====================================================

/*
Environment Variables for Database Configuration:

DB_HOST     - PostgreSQL host (default: localhost)
DB_PORT     - PostgreSQL port (default: 5432)
DB_USER     - PostgreSQL username (default: postgres)
DB_PASSWORD - PostgreSQL password (required)
DB_NAME     - Database name (default: qr_collection)
DB_SSLMODE  - SSL mode (default: disable)

Example .env file:
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password_here
DB_NAME=qr_collection
DB_SSLMODE=disable
*/