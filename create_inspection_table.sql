SET search_path TO cdms, public;

CREATE TABLE cdms.inspection (
    inspection_id SERIAL PRIMARY KEY,
    shipment_id INT NOT NULL,
    officer_id INT NOT NULL,
    inspection_date DATE NOT NULL,
    inspection_type inspection_type DEFAULT 'DOCUMENTARY',
    outcome insp_outcome DEFAULT 'PENDING',
    notes TEXT,
    
    CONSTRAINT fk_inspection_shipment 
        FOREIGN KEY (shipment_id) 
        REFERENCES cdms.shipment(shipment_id) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_inspection_officer 
        FOREIGN KEY (officer_id) 
        REFERENCES cdms.customs_officer(officer_id) 
        ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_inspection_ship ON cdms.inspection(shipment_id);
CREATE INDEX IF NOT EXISTS idx_inspection_officer ON cdms.inspection(officer_id);
CREATE INDEX IF NOT EXISTS idx_inspection_date ON cdms.inspection(inspection_date);
