CREATE TABLE customs_officer (
    officer_id        SERIAL        PRIMARY KEY,
    name              VARCHAR(100)  NOT NULL,
    badge_no          VARCHAR(30)   NOT NULL UNIQUE,
    department        VARCHAR(100)  NOT NULL,
    role              VARCHAR(50)   NOT NULL,
    assigned_port_id  INT,
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE,

    CONSTRAINT fk_officer_port
        FOREIGN KEY (assigned_port_id) REFERENCES port(port_id) ON DELETE SET NULL
);