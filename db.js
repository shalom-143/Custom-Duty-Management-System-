const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host:     process.env.DB_HOST,
  port:     process.env.DB_PORT,
  database: process.env.DB_NAME,
  user:     process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max:                 20,
  idleTimeoutMillis:   30000,
  connectionTimeoutMillis: 2000,
});

pool.connect()
  .then(client => {
    console.log('Database connected successfully!');
    client.release();
  })
  .catch(err => {
    console.error('Database connection error:', err.message);
  });

module.exports = pool;