 const express = require('express');
  const { Pool } = require('pg');
  const cors = require('cors');

  const app = express();
  const port = 3000;

  // Middleware
  app.use(cors());
  app.use(express.json());

  // Database connection
  const pool = new Pool({
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
  });

  // Initialize database table
  async function initDB() {
    try {
      await pool.query(`
        CREATE TABLE IF NOT EXISTS guestbook (
          id SERIAL PRIMARY KEY,
          name VARCHAR(100) NOT NULL,
          message TEXT NOT NULL,
          created_at TIMESTAMP DEFAULT NOW()
        )
      `);
      console.log('Database initialized');
    } catch (err) {
      console.error('Database init error:', err);
    }
  }

  // Routes
  app.get('/api/guestbook', async (req, res) => {
    try {
      const result = await pool.query('SELECT * FROM guestbook ORDER BY created_at DESC');
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  app.post('/api/guestbook', async (req, res) => {
    try {
      const { name, message } = req.body;
      const result = await pool.query(
        'INSERT INTO guestbook (name, message) VALUES ($1, $2) RETURNING *',
        [name, message]
      );
      res.json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  // Start server
  app.listen(port, () => {
    console.log(`Server running on port ${port}`);
    initDB();
  });