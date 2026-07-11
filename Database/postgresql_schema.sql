-- KriGo Car Rental Marketplace PostgreSQL Schema
-- Generated from the reviewed database documentation and ERD model.

-- Enable UUID generation support.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Drop existing objects to allow clean re-creation.
DROP TABLE IF EXISTS analytics_reports CASCADE;
DROP TABLE IF EXISTS ai_conversations CASCADE;
DROP TABLE IF EXISTS ai_recommendations CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS disputes CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS reservations CASCADE;
DROP TABLE IF EXISTS vehicles CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS branches CASCADE;
DROP TABLE IF EXISTS agency_verifications CASCADE;
DROP TABLE IF EXISTS agencies CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS users CASCADE;

DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS account_status CASCADE;
DROP TYPE IF EXISTS verification_status CASCADE;
DROP TYPE IF EXISTS reservation_status CASCADE;
DROP TYPE IF EXISTS payment_status CASCADE;
DROP TYPE IF EXISTS dispute_status CASCADE;
DROP TYPE IF EXISTS vehicle_status CASCADE;

-- Enumerated types.
CREATE TYPE user_role AS ENUM ('customer', 'agency', 'employee', 'administrator');
CREATE TYPE account_status AS ENUM ('active', 'inactive', 'suspended', 'pending');
CREATE TYPE verification_status AS ENUM ('pending', 'verified', 'rejected');
CREATE TYPE reservation_status AS ENUM ('pending', 'confirmed', 'active', 'completed', 'cancelled');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
CREATE TYPE dispute_status AS ENUM ('open', 'under_review', 'resolved', 'rejected');
CREATE TYPE vehicle_status AS ENUM ('available', 'reserved', 'maintenance', 'unavailable');

-- Core user accounts.
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    role user_role NOT NULL DEFAULT 'customer',
    account_status account_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_users_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Customer profiles linked to user accounts.
CREATE TABLE customers (
    customer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    driver_license VARCHAR(50) UNIQUE,
    date_of_birth DATE,
    address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_customers_driver_license CHECK (driver_license IS NULL OR length(trim(driver_license)) > 0)
);

-- Agency profiles linked to user accounts.
CREATE TABLE agencies (
    agency_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    agency_name VARCHAR(150) NOT NULL,
    business_license VARCHAR(100) UNIQUE,
    verification_status verification_status NOT NULL DEFAULT 'pending',
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Agency verification workflow details.
CREATE TABLE agency_verifications (
    verification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL UNIQUE REFERENCES agencies(agency_id) ON DELETE CASCADE,
    verified_by VARCHAR(100),
    verification_notes TEXT,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Branches operating under agencies.
CREATE TABLE branches (
    branch_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES agencies(agency_id) ON DELETE CASCADE,
    branch_name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Employees assigned to branches.
CREATE TABLE employees (
    employee_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branches(branch_id) ON DELETE CASCADE,
    full_name VARCHAR(100) NOT NULL,
    position VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_employees_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Fleet inventory.
CREATE TABLE vehicles (
    vehicle_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_id UUID NOT NULL REFERENCES agencies(agency_id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(branch_id) ON DELETE RESTRICT,
    brand VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year INT NOT NULL,
    fuel_type VARCHAR(30) NOT NULL,
    transmission VARCHAR(30),
    plate_number VARCHAR(20) UNIQUE,
    price_per_day NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    status vehicle_status NOT NULL DEFAULT 'available',
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_vehicles_year CHECK (year BETWEEN 1900 AND 2100),
    CONSTRAINT chk_vehicles_price CHECK (price_per_day >= 0)
);

-- Customer bookings.
CREATE TABLE reservations (
    reservation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES vehicles(vehicle_id) ON DELETE RESTRICT,
    pickup_date DATE NOT NULL,
    return_date DATE NOT NULL,
    total_price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    reservation_status reservation_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_reservations_dates CHECK (pickup_date <= return_date),
    CONSTRAINT chk_reservations_total CHECK (total_price >= 0)
);

-- Payments tied to reservations.
CREATE TABLE payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reservation_id UUID NOT NULL UNIQUE REFERENCES reservations(reservation_id) ON DELETE CASCADE,
    amount NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    payment_method VARCHAR(50) NOT NULL,
    payment_status payment_status NOT NULL DEFAULT 'pending',
    transaction_reference VARCHAR(100) UNIQUE,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_payments_amount CHECK (amount >= 0)
);

-- Optional customer reviews linked to completed rentals.
CREATE TABLE reviews (
    review_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reservation_id UUID NOT NULL UNIQUE REFERENCES reservations(reservation_id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    rating INT NOT NULL,
    comment TEXT,
    review_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5)
);

-- Reservation disputes.
CREATE TABLE disputes (
    dispute_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reservation_id UUID NOT NULL REFERENCES reservations(reservation_id) ON DELETE CASCADE,
    submitted_by UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status dispute_status NOT NULL DEFAULT 'open',
    resolution TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

-- Notifications sent to users.
CREATE TABLE notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- AI-generated recommendations.
CREATE TABLE ai_recommendations (
    recommendation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES vehicles(vehicle_id) ON DELETE CASCADE,
    recommendation_score NUMERIC(4,3) NOT NULL DEFAULT 0.000,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_ai_recommendations_score CHECK (recommendation_score BETWEEN 0.000 AND 1.000)
);

-- AI conversation history.
CREATE TABLE ai_conversations (
    conversation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    user_message TEXT NOT NULL,
    ai_response TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Administrative analytics reports.
CREATE TABLE analytics_reports (
    report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    generated_by UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    report_name VARCHAR(100) NOT NULL,
    report_type VARCHAR(50) NOT NULL,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    report_data JSONB NOT NULL DEFAULT '{}'::jsonb
);

-- Useful indexes for lookup and reporting.
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_account_status ON users(account_status);
CREATE INDEX idx_customers_user_id ON customers(user_id);
CREATE INDEX idx_agencies_verification_status ON agencies(verification_status);
CREATE INDEX idx_branches_agency_id ON branches(agency_id);
CREATE INDEX idx_employees_branch_id ON employees(branch_id);
CREATE INDEX idx_vehicles_agency_id ON vehicles(agency_id);
CREATE INDEX idx_vehicles_branch_id ON vehicles(branch_id);
CREATE INDEX idx_vehicles_status ON vehicles(status);
CREATE INDEX idx_reservations_customer_id ON reservations(customer_id);
CREATE INDEX idx_reservations_vehicle_id ON reservations(vehicle_id);
CREATE INDEX idx_reservations_dates ON reservations(pickup_date, return_date);
CREATE INDEX idx_payments_status ON payments(payment_status);
CREATE INDEX idx_reviews_rating ON reviews(rating);
CREATE INDEX idx_disputes_status ON disputes(status);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_ai_recommendations_customer_id ON ai_recommendations(customer_id);
CREATE INDEX idx_ai_recommendations_vehicle_id ON ai_recommendations(vehicle_id);
CREATE INDEX idx_ai_conversations_customer_id ON ai_conversations(customer_id);
CREATE INDEX idx_analytics_reports_generated_by ON analytics_reports(generated_by);

-- Optional comment block for documentation.
COMMENT ON TABLE users IS 'Authentication and profile accounts for all platform actors.';
COMMENT ON TABLE customers IS 'Customer-specific profile data.';
COMMENT ON TABLE agencies IS 'Agency organizations operating the fleet.';
COMMENT ON TABLE agency_verifications IS 'Verification workflow state for agencies.';
COMMENT ON TABLE branches IS 'Operational branches managed by agencies.';
COMMENT ON TABLE employees IS 'Employees assigned to branches.';
COMMENT ON TABLE vehicles IS 'Fleet inventory available for reservation.';
COMMENT ON TABLE reservations IS 'Rental bookings created by customers.';
COMMENT ON TABLE payments IS 'Payments linked to reservations.';
COMMENT ON TABLE reviews IS 'Customer feedback attached to rentals.';
COMMENT ON TABLE disputes IS 'Dispute cases linked to reservations.';
COMMENT ON TABLE notifications IS 'User notifications and alerts.';
COMMENT ON TABLE ai_recommendations IS 'AI-generated vehicle recommendations.';
COMMENT ON TABLE ai_conversations IS 'Customer interactions with AI assistant.';
COMMENT ON TABLE analytics_reports IS 'Administrative and analytics reporting data.';
