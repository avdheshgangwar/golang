#!/bin/bash

# QR Collection Project - Database Initialization Script
# This script helps set up the PostgreSQL database for the QR collection system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DB_NAME="qr_collection"
DB_USER="postgres"
DB_HOST="localhost"
DB_PORT="5432"
SCHEMA_FILE="database_schema.sql"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if PostgreSQL is running
check_postgres() {
    print_status "Checking PostgreSQL connection..."
    
    if pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USER > /dev/null 2>&1; then
        print_success "PostgreSQL is running and accessible"
        return 0
    else
        print_error "PostgreSQL is not running or not accessible"
        print_status "Please ensure PostgreSQL is running and accessible"
        return 1
    fi
}

# Function to check if database exists
check_database() {
    print_status "Checking if database '$DB_NAME' exists..."
    
    if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
        print_warning "Database '$DB_NAME' already exists"
        read -p "Do you want to drop and recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Dropping existing database..."
            dropdb -h $DB_HOST -p $DB_PORT -U $DB_USER $DB_NAME
            print_success "Database dropped successfully"
            return 0
        else
            print_status "Using existing database"
            return 1
        fi
    else
        print_status "Database '$DB_NAME' does not exist"
        return 0
    fi
}

# Function to create database
create_database() {
    print_status "Creating database '$DB_NAME'..."
    
    if createdb -h $DB_HOST -p $DB_PORT -U $DB_USER $DB_NAME; then
        print_success "Database '$DB_NAME' created successfully"
    else
        print_error "Failed to create database '$DB_NAME'"
        exit 1
    fi
}

# Function to check if schema file exists
check_schema_file() {
    print_status "Checking schema file..."
    
    if [ ! -f "$SCHEMA_FILE" ]; then
        print_error "Schema file '$SCHEMA_FILE' not found"
        print_status "Please ensure the schema file exists in the current directory"
        exit 1
    fi
    
    print_success "Schema file found"
}

# Function to apply schema
apply_schema() {
    print_status "Applying database schema..."
    
    if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f $SCHEMA_FILE; then
        print_success "Schema applied successfully"
    else
        print_error "Failed to apply schema"
        exit 1
    fi
}

# Function to verify schema
verify_schema() {
    print_status "Verifying schema application..."
    
    # Check if key tables exist
    TABLES=("clients" "banks" "bank_accounts" "qr_templates" "qr_codes" "transactions" "users" "audit_logs" "notifications")
    
    for table in "${TABLES[@]}"; do
        if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "\dt $table" > /dev/null 2>&1; then
            print_success "Table '$table' exists"
        else
            print_error "Table '$table' not found"
            exit 1
        fi
    done
    
    print_success "All tables verified successfully"
}

# Function to show database info
show_database_info() {
    print_status "Database setup completed successfully!"
    echo
    echo -e "${GREEN}Database Information:${NC}"
    echo "  Name: $DB_NAME"
    echo "  Host: $DB_HOST"
    echo "  Port: $DB_PORT"
    echo "  User: $DB_USER"
    echo
    echo -e "${GREEN}Next Steps:${NC}"
    echo "  1. Update your .env file with database credentials"
    echo "  2. Run 'go mod tidy' to install dependencies"
    echo "  3. Start your application with 'go run .'"
    echo
    echo -e "${GREEN}Sample Connection String:${NC}"
    echo "  postgresql://$DB_USER@$DB_HOST:$DB_PORT/$DB_NAME"
}

# Main execution
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  QR Collection DB Setup${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    
    # Check prerequisites
    check_postgres
    check_schema_file
    
    # Database setup
    if check_database; then
        create_database
    fi
    
    # Apply schema
    apply_schema
    
    # Verify setup
    verify_schema
    
    # Show completion info
    show_database_info
}

# Check if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi