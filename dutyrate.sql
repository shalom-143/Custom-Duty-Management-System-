-- SET search_path TO cdms;

-- Create duty_rate table
CREATE TABLE IF NOT EXISTS duty_rate (
    rate_id             SERIAL PRIMARY KEY,
    hs_code             VARCHAR(20) NOT NULL,
    duty_percentage     NUMERIC(5,2) CHECK (duty_percentage BETWEEN 0 AND 100),
    vat_rate            NUMERIC(5,2) CHECK (vat_rate BETWEEN 0 AND 100),
    excise_tax          NUMERIC(5,2) DEFAULT 0,
    transport_surcharge NUMERIC(5,2) DEFAULT 0,
    effective_date      DATE NOT NULL,
    expiry_date         DATE NULL
);

-- Create critical indexes for performance
CREATE INDEX IF NOT EXISTS idx_rate_hscode ON duty_rate (hs_code);
CREATE INDEX IF NOT EXISTS idx_rate_effective ON duty_rate (effective_date);

-- Insert sample duty rates (adjust as needed)
INSERT INTO duty_rate (hs_code, duty_percentage, vat_rate, excise_tax, transport_surcharge, effective_date, expiry_date) VALUES
('8703.22', 10.0, 19.5, 5.0, 2.5, '2024-01-01', NULL),
('8471.30', 0.0, 19.5, 0.0, 1.0, '2024-01-01', NULL),
('0901.11', 5.0, 5.0, 0.0, 0.5, '2024-01-01', '2024-12-31'),
('2710.12', 15.0, 19.5, 10.0, 3.0, '2024-01-01', NULL),
('1001.99', 0.0, 0.0, 0.0, 0.0, '2024-01-01', NULL)
ON CONFLICT DO NOTHING;

-- Quick verification query
SELECT * FROM duty_rate;
