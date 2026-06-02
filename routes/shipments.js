const express = require('express');
const router = express.Router();
const pool = require('../db');

// GET all shipments with pagination and filtering
router.get('/', async (req, res) => {
  try {
    const page      = parseInt(req.query.page)      || 1;
    const limit     = parseInt(req.query.limit)     || 10;
    const offset    = (page - 1) * limit;
    const { status, direction } = req.query;

    const conditions = [];
    const values     = [];

    // Build dynamic WHERE clause
    if (status) {
      values.push(status.toUpperCase());
      conditions.push(`Status = $${values.length}`);
    }

    if (direction) {
      values.push(direction.toUpperCase());
      conditions.push(`Direction = $${values.length}`);
    }

    const where = conditions.length > 0 ? 'WHERE ' + conditions.join(' AND ') : '';

    // Add pagination values
    values.push(limit);
    values.push(offset);

    const result = await pool.query(
      `SELECT * FROM Shipment ${where} ORDER BY ShipmentID ASC LIMIT $${values.length - 1} OFFSET $${values.length}`,
      values
    );

    // Get total count
    const countResult = await pool.query(
      `SELECT COUNT(*) FROM Shipment ${where}`,
      conditions.length > 0 ? values.slice(0, conditions.length) : []
    );

    const total = parseInt(countResult.rows[0].count);

    res.json({
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
      data: result.rows
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
// GET single shipment - optimized
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Validate ID format before hitting database
    if (!id || id.trim() === '')
      return res.status(400).json({ error: 'Invalid ShipmentID.' });

    const result = await pool.query(
      'SELECT * FROM Shipment WHERE ShipmentID = $1',
      [id.toUpperCase().trim()]
    );

    if (result.rows.length === 0)
      return res.status(404).json({ error: 'Shipment not found' });

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST create shipment - optimized
router.post('/', async (req, res) => {
  try {
    const { shipmentid, goodid, portid, traderid, shipmentdate, direction, status } = req.body;

    // Validate all fields present
    if (!shipmentid || !goodid || !portid || !traderid || !shipmentdate || !direction || !status)
      return res.status(400).json({ error: 'All fields are required.' });

    // Validate date format
    if (isNaN(Date.parse(shipmentdate)))
      return res.status(400).json({ error: 'Invalid date format. Use YYYY-MM-DD.' });

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
        shipmentid.toUpperCase().trim(),
        goodid.toUpperCase().trim(),
        portid.toUpperCase().trim(),
        traderid.toUpperCase().trim(),
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

// DELETE shipment - optimized
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Validate ID before hitting database
    if (!id || id.trim() === '')
      return res.status(400).json({ error: 'Invalid ShipmentID.' });

    const result = await pool.query(
      'DELETE FROM Shipment WHERE ShipmentID = $1 RETURNING *',
      [id.toUpperCase().trim()]
    );

    if (result.rows.length === 0)
      return res.status(404).json({ error: 'Shipment not found' });

    res.json({ message: 'Deleted successfully', deleted: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


module.exports = router;