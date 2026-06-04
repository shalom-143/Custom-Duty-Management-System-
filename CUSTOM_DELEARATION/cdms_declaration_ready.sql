-- Connect to correct schema
CREATE SCHEMA IF NOT EXISTS dc;
SET search_path TO dc;

-- Enable password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- ============================================================
-- ENUM TYPES
-- ============================================================
CREATE TYPE trader_type     AS ENUM ('INDIVIDUAL', 'COMPANY');
CREATE TYPE port_type       AS ENUM ('SEA', 'LAND');
CREATE TYPE direction_type  AS ENUM ('IMPORT', 'EXPORT');
CREATE TYPE ship_status     AS ENUM ('PENDING', 'IN_TRANSIT', 'ARRIVED', 'CLEARED', 'HELD');
CREATE TYPE pay_status      AS ENUM ('PENDING', 'PAID', 'OVERDUE');
CREATE TYPE pay_method      AS ENUM ('BANK_TRANSFER', 'MOBILE_MONEY', 'CASH', 'CHEQUE');
CREATE TYPE doc_type        AS ENUM ('BILL_OF_LADING', 'INVOICE', 'PACKING_LIST', 'CERTIFICATE_OF_ORIGIN', 'WAYBILL', 'PERMIT', 'DECLARATION_FORM');
CREATE TYPE decl_status     AS ENUM ('DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'PAID');


-- ============================================================
-- TABLES
-- ============================================================

-- 1. COUNTRY
CREATE TABLE country (
    country_id  SERIAL         PRIMARY KEY,
    name        VARCHAR(100)   NOT NULL UNIQUE,
    iso_code    CHAR(2)        NOT NULL UNIQUE,
    region      VARCHAR(100),
    created_at  TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

-- 2. CURRENCY
CREATE TABLE currency (
    currency_id   SERIAL         PRIMARY KEY,
    name          VARCHAR(100)   NOT NULL UNIQUE,
    code          CHAR(3)        NOT NULL UNIQUE,
    symbol        VARCHAR(5),
    exchange_rate NUMERIC(15,6)  NOT NULL DEFAULT 1,
    created_at    TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

-- 3. TRADER
CREATE TABLE trader (
    trader_id   SERIAL         PRIMARY KEY,
    name        VARCHAR(100)   NOT NULL,
    address     VARCHAR(200)   NOT NULL,
    phone       VARCHAR(20)    NOT NULL,
    email       VARCHAR(100)   NOT NULL UNIQUE,
    tin         VARCHAR(50)    NOT NULL UNIQUE,
    national_id VARCHAR(50),
    trader_type trader_type    NOT NULL,
    country_id  INT            REFERENCES country(country_id) ON DELETE SET NULL,
    created_at  TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_national_id CHECK (
        trader_type = 'COMPANY'
        OR (trader_type = 'INDIVIDUAL' AND national_id IS NOT NULL)
    )
);

-- 4. GOODS
CREATE TABLE goods (
    goods_id          SERIAL         PRIMARY KEY,
    description       VARCHAR(200)   NOT NULL,
    hs_code           VARCHAR(20)    NOT NULL,
    category          VARCHAR(100)   NOT NULL,
    unit_of_measure   VARCHAR(30)    NOT NULL,
    country_of_origin VARCHAR(60)    NOT NULL,
    created_at        TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

-- 5. PORT
CREATE TABLE port (
    port_id         SERIAL         PRIMARY KEY,
    port_code       VARCHAR(10)    NOT NULL UNIQUE,
    name            VARCHAR(100)   NOT NULL,
    location        VARCHAR(100)   NOT NULL,
    port_type       port_type      NOT NULL,
    country_id      INT            REFERENCES country(country_id) ON DELETE SET NULL,
    capacity_tonnes NUMERIC(12,2),
    is_active       BOOLEAN        NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

-- 6. SHIPMENT
CREATE TABLE shipment (
    shipment_id        SERIAL          PRIMARY KEY,
    trader_id          INT             NOT NULL REFERENCES trader(trader_id) ON DELETE RESTRICT,
    port_id            INT             NOT NULL REFERENCES port(port_id) ON DELETE RESTRICT,
    shipment_date      DATE            NOT NULL,
    direction          direction_type  NOT NULL,
    status             ship_status     NOT NULL DEFAULT 'PENDING',
    transport_mode     port_type       NOT NULL,
    bill_of_lading_no  VARCHAR(50),
    declaration_status decl_status     NOT NULL DEFAULT 'DRAFT',
    declared_at        TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- 7. SHIPMENT ITEM
CREATE TABLE shipment_item (
    item_id        SERIAL          PRIMARY KEY,
    shipment_id    INT             NOT NULL REFERENCES shipment(shipment_id) ON DELETE CASCADE,
    goods_id       INT             NOT NULL REFERENCES goods(goods_id) ON DELETE RESTRICT,
    quantity       NUMERIC(10,2)   NOT NULL,
    declared_value NUMERIC(15,2)   NOT NULL,
    weight_kg      NUMERIC(10,2)   NOT NULL,
    currency_id    INT             REFERENCES currency(currency_id) ON DELETE SET NULL,
    created_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_quantity       CHECK (quantity       > 0),
    CONSTRAINT chk_declared_value CHECK (declared_value > 0),
    CONSTRAINT chk_weight         CHECK (weight_kg      > 0)
);

-- 8. DUTY RATE
CREATE TABLE duty_rate (
    rate_id             SERIAL         PRIMARY KEY,
    hs_code             VARCHAR(20)    NOT NULL,
    duty_percentage     NUMERIC(5,2)   NOT NULL DEFAULT 0,
    vat_rate            NUMERIC(5,2)   NOT NULL DEFAULT 19.25,
    excise_tax          NUMERIC(5,2)   NOT NULL DEFAULT 0,
    transport_surcharge NUMERIC(5,2)   NOT NULL DEFAULT 0,
    effective_date      DATE           NOT NULL,
    expiry_date         DATE,
    created_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_duty      CHECK (duty_percentage    BETWEEN 0 AND 100),
    CONSTRAINT chk_vat       CHECK (vat_rate            BETWEEN 0 AND 100),
    CONSTRAINT chk_excise    CHECK (excise_tax          BETWEEN 0 AND 100),
    CONSTRAINT chk_surcharge CHECK (transport_surcharge BETWEEN 0 AND 100),
    CONSTRAINT chk_dates     CHECK (expiry_date IS NULL OR expiry_date > effective_date)
);
CREATE UNIQUE INDEX idx_duty_rate_active ON duty_rate(hs_code, effective_date);

-- 9. DUTY CALCULATION
CREATE TABLE duty_calculation (
    calc_id       SERIAL          PRIMARY KEY,
    item_id       INT             NOT NULL UNIQUE REFERENCES shipment_item(item_id) ON DELETE CASCADE,
    rate_id       INT             NOT NULL REFERENCES duty_rate(rate_id) ON DELETE RESTRICT,
    duty_amount   NUMERIC(15,2)   NOT NULL DEFAULT 0,
    vat_amount    NUMERIC(15,2)   NOT NULL DEFAULT 0,
    excise_amount NUMERIC(15,2)   NOT NULL DEFAULT 0,
    calculated_at TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_duty_amt   CHECK (duty_amount   >= 0),
    CONSTRAINT chk_vat_amt    CHECK (vat_amount     >= 0),
    CONSTRAINT chk_excise_amt CHECK (excise_amount  >= 0)
);

-- 10. PAYMENT
CREATE TABLE payment (
    payment_id   SERIAL          PRIMARY KEY,
    trader_id    INT             NOT NULL REFERENCES trader(trader_id) ON DELETE RESTRICT,
    calc_id      INT             NOT NULL UNIQUE REFERENCES duty_calculation(calc_id) ON DELETE RESTRICT,
    amount       NUMERIC(15,2)   NOT NULL,
    payment_date DATE            NOT NULL DEFAULT CURRENT_DATE,
    method       pay_method      NOT NULL DEFAULT 'BANK_TRANSFER',
    status       pay_status      NOT NULL DEFAULT 'PENDING',
    reference_no VARCHAR(80),
    currency_id  INT             REFERENCES currency(currency_id) ON DELETE SET NULL,
    notes        TEXT,
    created_at   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_amount CHECK (amount > 0)
);

-- 11. DOCUMENT
CREATE TABLE document (
    document_id   SERIAL          PRIMARY KEY,
    shipment_id   INT             NOT NULL REFERENCES shipment(shipment_id) ON DELETE CASCADE,
    document_type doc_type        NOT NULL,
    file_name     VARCHAR(255)    NOT NULL,
    file_path     VARCHAR(500),
    uploaded_at   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    status        VARCHAR(50)     NOT NULL DEFAULT 'ACTIVE'
                                  CHECK (status IN ('ACTIVE','ARCHIVED','REJECTED'))
);

-- 12. AUDIT LOG
CREATE TABLE audit_log (
    audit_id   SERIAL          PRIMARY KEY,
    table_name VARCHAR(100)    NOT NULL,
    record_id  INT             NOT NULL,
    action     VARCHAR(10)     NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE')),
    changed_by VARCHAR(150)    DEFAULT CURRENT_USER,
    changed_at TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    old_data   JSONB,
    new_data   JSONB
);


-- ============================================================
-- INDEXES
-- ============================================================

-- B-Tree
CREATE INDEX idx_trader_name          ON trader(name);
CREATE INDEX idx_shipment_trader      ON shipment(trader_id);
CREATE INDEX idx_shipment_port        ON shipment(port_id);
CREATE INDEX idx_shipment_date        ON shipment(shipment_date);
CREATE INDEX idx_shipment_status      ON shipment(status);
CREATE INDEX idx_shipment_decl_status ON shipment(declaration_status);
CREATE INDEX idx_shipment_mode        ON shipment(transport_mode);
CREATE INDEX idx_si_shipment          ON shipment_item(shipment_id);
CREATE INDEX idx_si_goods             ON shipment_item(goods_id);
CREATE INDEX idx_goods_hscode         ON goods(hs_code);
CREATE INDEX idx_rate_hscode          ON duty_rate(hs_code);
CREATE INDEX idx_rate_effective       ON duty_rate(effective_date);
CREATE INDEX idx_payment_trader       ON payment(trader_id);
CREATE INDEX idx_payment_status       ON payment(status);
CREATE INDEX idx_payment_date         ON payment(payment_date);
CREATE INDEX idx_document_shipment    ON document(shipment_id);
CREATE INDEX idx_audit_table          ON audit_log(table_name);

-- Composite
CREATE INDEX idx_shipment_mode_status   ON shipment(transport_mode, status);
CREATE INDEX idx_shipment_trader_status ON shipment(trader_id, declaration_status);
CREATE INDEX idx_payment_trader_status  ON payment(trader_id, status);

-- Partial
CREATE INDEX idx_pending_payments   ON payment(status)              WHERE status = 'PENDING';
CREATE INDEX idx_active_ports       ON port(is_active)              WHERE is_active = TRUE;
CREATE INDEX idx_draft_declarations ON shipment(declaration_status) WHERE declaration_status = 'DRAFT';
CREATE INDEX idx_submitted_decl     ON shipment(declaration_status) WHERE declaration_status = 'SUBMITTED';

-- BRIN (large date-ordered tables)
CREATE INDEX idx_audit_brin    ON audit_log USING BRIN (changed_at);
CREATE INDEX idx_payment_brin  ON payment   USING BRIN (payment_date);
CREATE INDEX idx_shipment_brin ON shipment  USING BRIN (shipment_date);

-- GIN (search inside JSONB)
CREATE INDEX idx_audit_old_data ON audit_log USING GIN (old_data);
CREATE INDEX idx_audit_new_data ON audit_log USING GIN (new_data);

-- Hash (exact equality lookups)
CREATE INDEX idx_trader_email_hash ON trader USING HASH (email);
CREATE INDEX idx_trader_tin_hash   ON trader USING HASH (tin);
CREATE INDEX idx_goods_hscode_hash ON goods  USING HASH (hs_code);


-- ============================================================
-- TRIGGERS AND FUNCTIONS
-- ============================================================

-- 1. AUTO DUTY CALCULATION
CREATE OR REPLACE FUNCTION fn_auto_calculate_duty()
RETURNS TRIGGER AS $$
DECLARE
    v_rate        duty_rate%ROWTYPE;
    v_duty_amount NUMERIC(15,2);
    v_vat_amount  NUMERIC(15,2);
    v_excise_amt  NUMERIC(15,2);
    v_hs_code     VARCHAR(20);
BEGIN
    SELECT hs_code INTO v_hs_code FROM goods WHERE goods_id = NEW.goods_id;
    SELECT * INTO v_rate FROM duty_rate
    WHERE  hs_code = v_hs_code
      AND  effective_date <= CURRENT_DATE
      AND  (expiry_date IS NULL OR expiry_date > CURRENT_DATE)
    ORDER BY effective_date DESC LIMIT 1;
    IF NOT FOUND THEN
        RAISE NOTICE 'No active duty rate for HS code %. Duty set to 0.', v_hs_code;
        INSERT INTO duty_calculation (item_id, rate_id, duty_amount, vat_amount, excise_amount)
        VALUES (NEW.item_id, 1, 0, 0, 0);
        RETURN NEW;
    END IF;
    v_duty_amount := ROUND(NEW.declared_value * v_rate.duty_percentage  / 100, 2);
    v_vat_amount  := ROUND(NEW.declared_value * v_rate.vat_rate         / 100, 2);
    v_excise_amt  := ROUND(NEW.declared_value * v_rate.excise_tax       / 100, 2);
    INSERT INTO duty_calculation (item_id, rate_id, duty_amount, vat_amount, excise_amount)
    VALUES (NEW.item_id, v_rate.rate_id, v_duty_amount, v_vat_amount, v_excise_amt);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_duty
AFTER INSERT ON shipment_item
FOR EACH ROW EXECUTE FUNCTION fn_auto_calculate_duty();

-- 2. AUTO PAYMENT CREATION
CREATE OR REPLACE FUNCTION fn_auto_create_payment()
RETURNS TRIGGER AS $$
DECLARE
    v_trader_id INT;
    v_total     NUMERIC(15,2);
BEGIN
    SELECT s.trader_id INTO v_trader_id
    FROM shipment_item si
    JOIN shipment s ON s.shipment_id = si.shipment_id
    WHERE si.item_id = NEW.item_id;
    v_total := NEW.duty_amount + NEW.vat_amount + NEW.excise_amount;
    INSERT INTO payment (trader_id, calc_id, amount, payment_date, method, status)
    VALUES (v_trader_id, NEW.calc_id, v_total, CURRENT_DATE, 'BANK_TRANSFER', 'PENDING');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_payment
AFTER INSERT ON duty_calculation
FOR EACH ROW EXECUTE FUNCTION fn_auto_create_payment();

-- 3. BLOCK INACTIVE PORT
CREATE OR REPLACE FUNCTION fn_check_port_active()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT (SELECT is_active FROM port WHERE port_id = NEW.port_id) THEN
        RAISE EXCEPTION 'Cannot create declaration: Port % is inactive.', NEW.port_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_port_active
BEFORE INSERT ON shipment
FOR EACH ROW EXECUTE FUNCTION fn_check_port_active();

-- 4. AUTO DECLARATION CLEARANCE
CREATE OR REPLACE FUNCTION fn_clear_declaration_on_payment()
RETURNS TRIGGER AS $$
DECLARE
    v_shipment_id INT;
BEGIN
    IF NEW.status = 'PAID' AND OLD.status <> 'PAID' THEN
        SELECT si.shipment_id INTO v_shipment_id
        FROM duty_calculation dc
        JOIN shipment_item si ON si.item_id = dc.item_id
        WHERE dc.calc_id = NEW.calc_id;
        IF NOT EXISTS (
            SELECT 1
            FROM shipment_item si2
            JOIN duty_calculation dc2 ON dc2.item_id = si2.item_id
            JOIN payment p2           ON p2.calc_id  = dc2.calc_id
            WHERE si2.shipment_id = v_shipment_id
              AND p2.status <> 'PAID'
        ) THEN
            UPDATE shipment
            SET status             = 'CLEARED',
                declaration_status = 'PAID'
            WHERE shipment_id = v_shipment_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_clear_declaration
AFTER UPDATE OF status ON payment
FOR EACH ROW EXECUTE FUNCTION fn_clear_declaration_on_payment();

-- 5. AUDIT LOG
CREATE OR REPLACE FUNCTION fn_audit_log()
RETURNS TRIGGER AS $$
DECLARE
    v_record_id INT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_record_id := (to_jsonb(OLD) ->> 'shipment_id')::INT;
        INSERT INTO audit_log (table_name, record_id, action, old_data)
        VALUES (TG_TABLE_NAME, COALESCE(v_record_id, 0), TG_OP, to_jsonb(OLD));
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        v_record_id := (to_jsonb(NEW) ->> 'shipment_id')::INT;
        INSERT INTO audit_log (table_name, record_id, action, old_data, new_data)
        VALUES (TG_TABLE_NAME, COALESCE(v_record_id, 0), TG_OP, to_jsonb(OLD), to_jsonb(NEW));
    ELSIF TG_OP = 'INSERT' THEN
        v_record_id := (to_jsonb(NEW) ->> 'shipment_id')::INT;
        INSERT INTO audit_log (table_name, record_id, action, new_data)
        VALUES (TG_TABLE_NAME, COALESCE(v_record_id, 0), TG_OP, to_jsonb(NEW));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_shipment
AFTER INSERT OR UPDATE OR DELETE ON shipment
FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

CREATE TRIGGER trg_audit_payment
AFTER INSERT OR UPDATE OR DELETE ON payment
FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

CREATE TRIGGER trg_audit_shipment_item
AFTER INSERT OR UPDATE OR DELETE ON shipment_item
FOR EACH ROW EXECUTE FUNCTION fn_audit_log();


-- ============================================================
-- VIEWS
-- ============================================================

CREATE VIEW v_declaration_summary AS
SELECT s.shipment_id, s.shipment_date, s.direction,
       s.transport_mode, s.status AS shipment_status,
       s.declaration_status, s.bill_of_lading_no, s.declared_at,
       t.name AS trader_name, t.tin AS trader_tin, t.trader_type,
       p.name AS port_name, p.location AS port_location, p.port_type
FROM shipment s
JOIN trader t ON t.trader_id = s.trader_id
JOIN port   p ON p.port_id   = s.port_id;

CREATE VIEW v_duty_summary AS
SELECT dc.calc_id, si.shipment_id, si.item_id,
       g.description AS goods_description, g.hs_code, g.category,
       si.quantity, si.declared_value, si.weight_kg,
       dc.duty_amount, dc.vat_amount, dc.excise_amount,
       (dc.duty_amount + dc.vat_amount + dc.excise_amount) AS total_payable,
       dc.calculated_at
FROM duty_calculation dc
JOIN shipment_item si ON si.item_id = dc.item_id
JOIN goods         g  ON g.goods_id = si.goods_id;

CREATE VIEW v_payment_status AS
SELECT p.payment_id, p.payment_date, p.amount, p.method,
       p.status, p.reference_no,
       t.name AS trader_name, t.tin AS trader_tin,
       s.shipment_id, s.declaration_status, s.transport_mode,
       (dc.duty_amount + dc.vat_amount + dc.excise_amount) AS duty_total
FROM payment p
JOIN trader           t  ON t.trader_id   = p.trader_id
JOIN duty_calculation dc ON dc.calc_id    = p.calc_id
JOIN shipment_item    si ON si.item_id    = dc.item_id
JOIN shipment         s  ON s.shipment_id = si.shipment_id;

CREATE MATERIALIZED VIEW mv_declaration_revenue AS
SELECT s.transport_mode, s.direction,
       COUNT(DISTINCT s.shipment_id)                          AS total_declarations,
       SUM(dc.duty_amount)                                    AS total_duty,
       SUM(dc.vat_amount)                                     AS total_vat,
       SUM(dc.excise_amount)                                  AS total_excise,
       SUM(dc.duty_amount + dc.vat_amount + dc.excise_amount) AS total_revenue
FROM duty_calculation dc
JOIN shipment_item si ON si.item_id    = dc.item_id
JOIN shipment      s  ON s.shipment_id = si.shipment_id
GROUP BY s.transport_mode, s.direction;


-- ============================================================
-- SECURITY
-- ============================================================
CREATE ROLE declaration_admin;
CREATE ROLE declaration_officer;
CREATE ROLE declaration_finance;
CREATE ROLE declaration_viewer;

GRANT USAGE ON SCHEMA dc TO declaration_viewer;
GRANT SELECT ON ALL TABLES IN SCHEMA dc TO declaration_viewer;

GRANT USAGE ON SCHEMA dc TO declaration_finance;
GRANT SELECT ON ALL TABLES IN SCHEMA dc TO declaration_finance;
GRANT INSERT, UPDATE ON payment TO declaration_finance;

GRANT USAGE ON SCHEMA dc TO declaration_officer;
GRANT SELECT ON ALL TABLES IN SCHEMA dc TO declaration_officer;
GRANT INSERT, UPDATE ON shipment, shipment_item, document TO declaration_officer;

GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA dc TO declaration_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA dc TO declaration_admin;


-- ============================================================
-- SAMPLE DATA
-- ============================================================

INSERT INTO country (name, iso_code, region) VALUES
('Cameroon', 'CM', 'Africa'),  ('China',    'CN', 'Asia'),
('Germany',  'DE', 'Europe'),  ('Nigeria',  'NG', 'Africa'),
('Malaysia', 'MY', 'Asia'),    ('India',    'IN', 'Asia'),
('Senegal',  'SN', 'Africa'),  ('Ukraine',  'UA', 'Europe');

INSERT INTO currency (name, code, symbol, exchange_rate) VALUES
('CFA Franc',    'XAF', 'Fr', 1.000000),
('US Dollar',    'USD', '$',  610.500000),
('Euro',         'EUR', '€',  660.250000),
('Chinese Yuan', 'CNY', '¥',  84.300000);

INSERT INTO port (port_code, name, location, port_type, country_id, capacity_tonnes, is_active) VALUES
('CM-DLA', 'Port of Douala',      'Douala, Littoral',    'SEA',  1, 30000.00, TRUE),
('CM-KRI', 'Port of Kribi',       'Kribi, South',        'SEA',  1, 15000.00, TRUE),
('CM-EKO', 'Ekok Land Border',    'Mamfe, South West',   'LAND', 1, NULL,     TRUE),
('CM-NGA', 'Ngaoundere Dry Port', 'Ngaoundere, Adamawa', 'LAND', 1, 5000.00,  TRUE);

INSERT INTO trader (name, address, phone, email, tin, national_id, trader_type, country_id) VALUES
('SABC Brasseries',     '12 Rue de Douala, Douala',  '+237233000001', 'contact@sabc.cm',   'TIN-CM-001', NULL,            'COMPANY',    1),
('COTCO Pipeline Corp', '8 Industrial Zone, Douala', '+237233000002', 'ops@cotco.cm',      'TIN-CM-002', NULL,            'COMPANY',    1),
('Ngono Marie Claire',  '22 Marche Central, Kribi',  '+237699000001', 'ngono.mc@yahoo.fr', 'TIN-CM-003', 'NID-237-00441', 'INDIVIDUAL', 1),
('Momo Jean-Pierre',    '14 Quartier Nkol, Bamenda', '+237699000002', 'momo.jp@gmail.com', 'TIN-CM-004', 'NID-237-00882', 'INDIVIDUAL', 1);

INSERT INTO goods (description, hs_code, category, unit_of_measure, country_of_origin) VALUES
('Refined Vegetable Oil',      '1507.90', 'Food & Beverages', 'Litres',    'Malaysia'),
('Industrial Machinery Parts', '8431.49', 'Machinery',        'Units',     'Germany'),
('Cotton Fabric (raw)',         '5208.11', 'Textiles',         'Metres',    'China'),
('Portland Cement',            '2523.29', 'Construction',     'Tonnes',    'Nigeria'),
('Laptop Computers',           '8471.30', 'Electronics',      'Units',     'China'),
('Frozen Fish',                '0303.89', 'Food & Beverages', 'Kilograms', 'Senegal'),
('Pharmaceutical Tablets',     '3004.90', 'Pharmaceuticals',  'Units',     'India'),
('Steel Bars',                 '7214.20', 'Construction',     'Tonnes',    'Ukraine');

INSERT INTO duty_rate (hs_code, duty_percentage, vat_rate, excise_tax, transport_surcharge, effective_date) VALUES
('1507.90', 10.00, 19.25, 0.00, 2.00, '2024-01-01'),
('8431.49',  5.00, 19.25, 0.00, 1.50, '2024-01-01'),
('5208.11', 20.00, 19.25, 0.00, 2.50, '2024-01-01'),
('2523.29', 10.00, 19.25, 0.00, 1.00, '2024-01-01'),
('8471.30', 10.00, 19.25, 5.00, 2.00, '2024-01-01'),
('0303.89',  5.00, 19.25, 0.00, 1.50, '2024-01-01'),
('3004.90',  5.00, 19.25, 0.00, 1.00, '2024-01-01'),
('7214.20', 10.00, 19.25, 0.00, 2.00, '2024-01-01');

INSERT INTO shipment (trader_id, port_id, shipment_date, direction, transport_mode, bill_of_lading_no, declaration_status) VALUES
(1, 1, '2025-06-01', 'IMPORT', 'SEA',  'BL-2025-001', 'SUBMITTED'),
(4, 3, '2025-06-03', 'IMPORT', 'LAND', 'WB-2025-002', 'SUBMITTED'),
(2, 1, '2025-06-05', 'EXPORT', 'SEA',  'BL-2025-003', 'UNDER_REVIEW'),
(3, 2, '2025-06-07', 'IMPORT', 'SEA',  'BL-2025-004', 'DRAFT');

-- Each insert below auto-creates duty_calculation AND payment via triggers
INSERT INTO shipment_item (shipment_id, goods_id, quantity, declared_value, weight_kg, currency_id) VALUES
(1, 1, 5000.00, 2500000.00,  4500.00, 1),
(1, 5,  100.00, 8000000.00,   150.00, 1),
(2, 4, 2000.00, 1800000.00, 40000.00, 1),
(3, 3, 3000.00, 3600000.00,  2500.00, 1),
(4, 6, 1500.00,  900000.00,  1500.00, 1),
(4, 7, 5000.00, 4500000.00,    50.00, 1);

INSERT INTO document (shipment_id, document_type, file_name) VALUES
(1, 'BILL_OF_LADING',        'BL-2025-001.pdf'),
(1, 'INVOICE',               'INV-SABC-001.pdf'),
(1, 'PACKING_LIST',          'PL-SABC-001.pdf'),
(2, 'WAYBILL',               'WB-2025-002.pdf'),
(2, 'CERTIFICATE_OF_ORIGIN', 'COO-MOMO-001.pdf'),
(3, 'DECLARATION_FORM',      'DECL-COTCO-001.pdf');

-- Mark shipment 1 payments as PAID
-- This triggers auto-clearance: shipment 1 becomes CLEARED + PAID
UPDATE payment
SET    status       = 'PAID',
       reference_no = 'TRF-237-20250603-001'
WHERE  calc_id IN (
    SELECT dc.calc_id
    FROM   duty_calculation dc
    JOIN   shipment_item si ON si.item_id = dc.item_id
    WHERE  si.shipment_id = 1
);


-- ============================================================
-- VERIFICATION QUERIES — run these to confirm it all works
-- ============================================================

-- All declarations
SELECT * FROM v_declaration_summary ORDER BY shipment_date;

-- Duty breakdown per item
SELECT vd.shipment_id, ds.trader_name, ds.transport_mode,
       vd.goods_description, vd.declared_value,
       vd.duty_amount, vd.vat_amount, vd.excise_amount, vd.total_payable
FROM v_duty_summary vd
JOIN v_declaration_summary ds ON ds.shipment_id = vd.shipment_id
ORDER BY vd.shipment_id;

-- Payment status
SELECT * FROM v_payment_status ORDER BY payment_date;

-- Trigger chain proof: items + auto-created duty + payment
SELECT si.item_id, g.description, si.declared_value,
       dc.duty_amount, dc.vat_amount,
       (dc.duty_amount + dc.vat_amount + dc.excise_amount) AS total_payable,
       p.status AS payment_status
FROM shipment_item    si
JOIN goods            g  ON g.goods_id  = si.goods_id
JOIN duty_calculation dc ON dc.item_id  = si.item_id
JOIN payment          p  ON p.calc_id   = dc.calc_id
ORDER BY si.item_id;

-- Confirm shipment 1 auto-cleared
SELECT shipment_id, status, declaration_status
FROM shipment WHERE shipment_id = 1;

-- Revenue by transport mode
SELECT * FROM mv_declaration_revenue;

-- Audit trail
SELECT table_name, action, changed_by, changed_at
FROM audit_log ORDER BY changed_at DESC LIMIT 20;

