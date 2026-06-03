CREATE TABLE trader(
	TraderID VARCHAR(50) PRIMARY KEY,
	TraderName VARCHAR(255) NOT NULL,
	Address TEXT NOT NULL,
	Phone VARCHAR(20) NOT NULL,
	Email VARCHAR(255) UNIQUE NOT NULL,
	Tin VARCHAR(50) UNIQUE NOT NULL,
	TraderType VARCHAR(50) NOT NULL
	
    /* After you create the table, run this 
	--Constraints
    ALTER TABLE trader ADD CONSTRAINT chk_trader_type 
	CHECK (TraderType IN ('Importer', 'Exporter'));
	-- Audit timestamps for tracking & soft deletes
	ALTER TABLE trader 
  	ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW(),
  	ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW(),
  	ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
	-- Performance Indexes
	CREATE INDEX idx_trader_name ON trader(TraderName);
	CREATE INDEX idx_trader_type ON trader(TraderType);
	CREATE INDEX idx_trader_phone ON trader(Phone);*/
	);
