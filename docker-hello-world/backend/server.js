 const express = require('express');
  const { Pool } = require('pg');
  const cors = require('cors');
 const AWS = require('aws-sdk');

  const app = express();
  const port = 3000;

 // Configure AWS
 AWS.config.update({ region: 'us-east-1' });
 const sqs = new AWS.SQS();
 const ssm = new AWS.SSM();

 // Parameter Store helper function
 async function getParameter(name) {
   try {
     const result = await ssm.getParameter({
       Name: name,
       WithDecryption: true
     }).promise();
     return result.Parameter.Value;
   } catch (error) {
     console.error(`Failed to get parameter ${name}:`, error);
     throw error;
   }
 }

 // Load configuration from Parameter Store
 let appConfig = {};

  // Middleware
  app.use(cors());
  app.use(express.json());

  // Database connection (will be initialized after loading config)
  let pool;

  // Load configuration from Parameter Store
  async function loadConfig() {
    try {
      console.log('Loading configuration from Parameter Store...');
      appConfig = {
        dbHost: await getParameter('guestbook-db-host'),
        dbName: await getParameter('guestbook-db-name'),
        dbUser: await getParameter('guestbook-db-user'),
        dbPassword: await getParameter('guestbook-db-password'),
        dbPort: await getParameter('guestbook-db-port'),
        queueUrl: await getParameter('guestbook-sqs-queue-url')
      };
      
      // Initialize database connection with loaded config
      pool = new Pool({
        host: appConfig.dbHost,
        database: appConfig.dbName,
        user: appConfig.dbUser,
        password: appConfig.dbPassword,
        port: parseInt(appConfig.dbPort),
        ssl: {
          rejectUnauthorized: false
        }
      });
      
      console.log('Configuration loaded successfully');
    } catch (error) {
      console.error('Failed to load configuration:', error);
      throw error;
    }
  }

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

  // Health check endpoint
  app.get('/health', (req, res) => {
    res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
  });

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
      
      // Input validation
      if (!name || !message) {
        return res.status(400).json({ error: 'Name and message are required' });
      }
      if (typeof name !== 'string' || typeof message !== 'string') {
        return res.status(400).json({ error: 'Name and message must be strings' });
      }
      if (name.length > 100) {
        return res.status(400).json({ error: 'Name must be less than 100 characters' });
      }
      if (message.length > 1000) {
        return res.status(400).json({ error: 'Message must be less than 1000 characters' });
      }
      
      // Sanitize input
      const sanitizedName = name.trim().slice(0, 100);
      const sanitizedMessage = message.trim().slice(0, 1000);
      const result = await pool.query(
        'INSERT INTO guestbook (name, message) VALUES ($1, $2) RETURNING *',
        [sanitizedName, sanitizedMessage]
      );
      
      // Send notification to SQS
      const sqsMessage = {
        QueueUrl: appConfig.queueUrl,
        MessageBody: JSON.stringify({
          id: result.rows[0].id,
          name: result.rows[0].name,
          message: result.rows[0].message,
          created_at: result.rows[0].created_at
        })
      };
      
      try {
        await sqs.sendMessage(sqsMessage).promise();
        console.log('Notification sent to SQS for entry:', result.rows[0].id);
      } catch (sqsError) {
        console.error('Failed to send SQS message:', sqsError);
      }
      
      res.json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  // Start server
  async function startServer() {
    try {
      await loadConfig();
      await initDB();
      
      app.listen(port, '0.0.0.0', () => {
        console.log(`Server running on port ${port}`);
        console.log('✅ Guestbook API ready with Parameter Store configuration');
      });
    } catch (error) {
      console.error('Failed to start server:', error);
      process.exit(1);
    }
  }

  startServer();