const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

class TraderModel {
  static async create(traderData) {
    const { TraderID, TraderName, Address, Phone, Email, Tin, TraderType } = traderData;
    const query = `
      INSERT INTO trader (TraderID, TraderName, Address, Phone, Email, Tin, TraderType)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *;
    `;
    const values = [TraderID, TraderName, Address, Phone, Email, Tin, TraderType];
    const result = await pool.query(query, values);
    return result.rows[0];
  }

  static async findById(id) {
    const query = 'SELECT * FROM trader WHERE TraderID = $1';
    const result = await pool.query(query, [id]);
    return result.rows[0] || null;
  }

  static async findAll(limit = 50, offset = 0) {
    const query = 'SELECT * FROM trader ORDER BY TraderName LIMIT $1 OFFSET $2';
    const result = await pool.query(query, [limit, offset]);
    return result.rows;
  }

  static async update(id, traderData) {
    const { TraderName, Address, Phone, Email, Tin, TraderType } = traderData;
    const query = `
      UPDATE trader
      SET TraderName = $2, Address = $3, Phone = $4, Email = $5, Tin = $6, TraderType = $7
      WHERE TraderID = $1
      RETURNING *;
    `;
    const values = [id, TraderName, Address, Phone, Email, Tin, TraderType];
    const result = await pool.query(query, values);
    return result.rows[0] || null;
  }

  static async delete(id) {
    const query = 'DELETE FROM trader WHERE TraderID = $1 RETURNING *';
    const result = await pool.query(query, [id]);
    return result.rows[0] || null;
  }
}

module.exports = TraderModel;