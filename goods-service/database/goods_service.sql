-- ============================================
-- GOODS SERVICE DATABASE
-- Custom Duty Management System
-- ============================================

-- Create schema
CREATE SCHEMA IF NOT EXISTS cdms;
SET search_path TO cdms;

-- ============================================
-- ENUM TYPES
-- ============================================

CREATE TYPE goods_status AS ENUM ('ACTIVE', 'INACTIVE', 'OBSOLETE');
CREATE TYPE risk_level AS ENUM ('LOW', 'MEDIUM', 'HIGH');

-- ============================================
-- GOODS TABLE
-- ============================================

CREATE TABLE goods (
    -- Primary Key
    goods_id SERIAL PRIMARY KEY,
    
    -- Business Identifiers
    goods_code VARCHAR(50) UNIQUE NOT NULL,
    hs_code VARCHAR(20) NOT NULL,
    
    -- Basic Information
    name VARCHAR(500) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    subcategory VARCHAR(100),
    
    -- Physical Properties
    unit_of_measure VARCHAR(30) NOT NULL,
    weight_per_unit_kg NUMERIC(10,4),
    
    -- Origin
    country_of_origin VARCHAR(60) NOT NULL,
    
    -- Tax Rates
    base_duty_rate NUMERIC(5,2) DEFAULT 0,
    vat_rate NUMERIC(5,2) DEFAULT 0,
    
    -- Compliance Flags
    is_hazardous BOOLEAN DEFAULT FALSE,
    is_restricted BOOLEAN DEFAULT FALSE,
    requires_license BOOLEAN DEFAULT FALSE,
    
    -- Risk Management
    risk_rating risk_level DEFAULT 'LOW',
    
    -- Status
    status goods_status DEFAULT 'ACTIVE',
    
    -- Audit Trail
    created_by VARCHAR(100) DEFAULT CURRENT_USER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by VARCHAR(100),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Soft Delete
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT goods_hs_code_format CHECK (hs_code ~ '^\d{2}\.\d{2}\.\d{2}$')
);

-- ============================================
-- INDEXES for Performance
-- ============================================

CREATE INDEX idx_goods_hs_code ON goods(hs_code) WHERE NOT is_deleted;
CREATE INDEX idx_goods_category ON goods(category) WHERE NOT is_deleted;
CREATE INDEX idx_goods_code ON goods(goods_code) WHERE NOT is_deleted;
CREATE INDEX idx_goods_status ON goods(status) WHERE NOT is_deleted;
CREATE INDEX idx_goods_created ON goods(created_at DESC) WHERE NOT is_deleted;

-- Full-text search index
CREATE INDEX idx_goods_search ON goods USING GIN(
    to_tsvector('english', name || ' ' || COALESCE(description, ''))
);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Auto-update timestamp
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.updated_by = CURRENT_USER;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_goods_timestamp
    BEFORE UPDATE ON goods
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

-- Auto-generate goods_code
CREATE OR REPLACE FUNCTION generate_goods_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.goods_code IS NULL THEN
        NEW.goods_code := 'GOODS_' || LPAD(NEW.goods_id::TEXT, 8, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_goods_code
    BEFORE INSERT ON goods
    FOR EACH ROW
    EXECUTE FUNCTION generate_goods_code();

-- ============================================
-- SAMPLE DATA
-- ============================================

INSERT INTO goods (name, hs_code, category, unit_of_measure, country_of_origin, base_duty_rate) VALUES
('Toyota Hilux Pickup', '87.03.21', 'VEHICLES', 'UNIT', 'JAPAN', 25.00),
('Thai Jasmine Rice', '10.06.00', 'AGRICULTURE', 'KG', 'THAILAND', 10.00),
('Premium Motor Spirit', '27.10.11', 'PETROLEUM', 'LTR', 'NIGERIA', 5.00),
('Portland Cement', '25.23.10', 'CONSTRUCTION', 'KG', 'CAMEROON', 15.00),
('Laptop Computer', '84.71.30', 'ELECTRONICS', 'UNIT', 'CHINA', 20.00),
('Medical Face Mask', '63.07.90', 'MEDICAL', 'PIECE', 'VIETNAM', 0.00),
('Frozen Chicken', '02.07.14', 'FOOD', 'KG', 'BRAZIL', 35.00),
('Smartphone', '85.17.12', 'ELECTRONICS', 'UNIT', 'CHINA', 15.00),
('Diesel Fuel', '27.10.19', 'PETROLEUM', 'LTR', 'NIGERIA', 8.00),
('Cotton Fabric', '52.08.51', 'TEXTILES', 'METER', 'INDIA', 30.00);

-- ============================================
-- CREATE BACKEND USER
-- ============================================

-- Create user for backend connection
CREATE USER IF NOT EXISTS goods_user WITH PASSWORD 'goods123';

-- Grant permissions
GRANT CONNECT ON DATABASE cdms TO goods_user;
GRANT USAGE ON SCHEMA cdms TO goods_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA cdms TO goods_user;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA cdms TO goods_user;

-- ============================================
-- VERIFY SETUP
-- ============================================

SELECT 'Database Setup Complete!' as Status;
SELECT COUNT(*) as TotalGoods FROM goods;
GRANT CONNECT ON DATABASE cdms TO goods_user;
GRANT USAGE ON SCHEMA cdms TO goods_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA cdms TO goods_user;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA cdms TO goods_user;