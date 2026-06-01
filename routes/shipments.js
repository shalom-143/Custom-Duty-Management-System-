const express = require('express');
const router = express.Router();
const pool = require('../db');

// GET all shipments
router.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM Shipment ORDER BY ShipmentID ASC');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET single shipment
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      'SELECT * FROM Shipment WHERE ShipmentID = $1', [id.toUpperCase()]
    );
    if (result.rows.length === 0)
      return res.status(404).json({ error: 'Shipment not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST create shipment
router.post('/', async (req, res) => {
  try {
    const { shipmentid, goodid, portid, traderid, shipmentdate, direction, status } = req.body;

    // Validate all fields present
    if (!shipmentid || !goodid || !portid || !traderid || !shipmentdate || !direction || !status)
      return res.status(400).json({ error: 'All fields are required.' });

    // Validate direction
    if (!['IMPORT', 'EXPORT'].includes(direction.toUpperCase()))
      return res.status(400).json({ error: 'Direction must be IMPORT or EXPORT.' });

    // Validate status
    const validStatuses = ['PENDING', 'IN_TRANSIT', 'DELIVERED', 'CANCELLED'];
    if (!validStatuses.includes(status.toUpperCase()))
      return res.status(400).json({ error: `Status must be one of: ${validStatuses.join(', ')}` });

    const result = await pool.query(
      `INSERT INTO Shipment (ShipmentID, GoodID, PortID, TraderID, ShipmentDate, Direction, Status)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [
        shipmentid.toUpperCase(),
        goodid.toUpperCase(),
        portid.toUpperCase(),
        traderid.toUpperCase(),
        shipmentdate,
        direction.toUpperCase(),
        status.toUpperCase()
      ]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    if (err.code === '23503')
      return res.status(400).json({ error: 'Invalid GoodID, PortID, or TraderID — record does not exist.' });
    if (err.code === '23505')
      return res.status(400).json({ error: 'ShipmentID already exists.' });
    res.status(500).json({ error: err.message });
  }
});

// PUT update shipment
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { goodid, portid, traderid, shipmentdate, direction, status } = req.body;

    // Validate at least one field is provided
    if (!goodid && !portid && !traderid && !shipmentdate && !direction && !status)
      return res.status(400).json({ error: 'At least one field is required to update.' });

    // Validate direction if provided
    if (direction && !['IMPORT', 'EXPORT'].includes(direction.toUpperCase()))
      return res.status(400).json({ error: 'Direction must be IMPORT or EXPORT.' });

    // Validate status if provided
    const validStatuses = ['PENDING', 'IN_TRANSIT', 'DELIVERED', 'CANCELLED'];
    if (status && !validStatuses.includes(status.toUpperCase()))
      return res.status(400).json({ error: `Status must be one of: ${validStatuses.join(', ')}` });

    const result = await pool.query(
      `UPDATE Shipment
       SET GoodID       = COALESCE($1, GoodID),
           PortID       = COALESCE($2, PortID),
           TraderID     = COALESCE($3, TraderID),
           ShipmentDate = COALESCE($4, ShipmentDate),
           Direction    = COALESCE($5, Direction),
           Status       = COALESCE($6, Status)
       WHERE ShipmentID = $7
       RETURNING *`,
      [
        goodid?.toUpperCase(),
        portid?.toUpperCase(),
        traderid?.toUpperCase(),
        shipmentdate,
        direction?.toUpperCase(),
        status?.toUpperCase(),
        id.toUpperCase()
      ]
    );

    if (result.rows.length === 0)
      return res.status(404).json({ error: 'Shipment not found' });

    res.json(result.rows[0]);
  } catch (err) {
    if (err.code === '23503')
      return res.status(400).json({ error: 'Invalid GoodID, PortID, or TraderID — record does not exist.' });
    res.status(500).json({ error: err.message });
  }
});

// DELETE shipment
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      'DELETE FROM Shipment WHERE ShipmentID = $1 RETURNING *',
      [id.toUpperCase()]
    );
    if (result.rows.length === 0)
      return res.status(404).json({ error: 'Shipment not found' });
    res.json({ message: 'Deleted successfully', deleted: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;