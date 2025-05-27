const mysql = require('mysql2');
require('dotenv').config();

// Create a connection pool instead of a single connection
const pool = mysql.createPool({
  host: 'sql12.freesqldatabase.com',
  user: 'sql12781540',
  password: 'rijjEPTqBB',
  database: 'sql12781540',
  port: 3306,
  connectionLimit: 5,
  queueLimit: 0,
  acquireTimeout: 30000,
  idleTimeout: 60000,
  ssl: false,
  charset: 'utf8mb4',
  reconnect: true
});

// Test the connection
pool.getConnection((err, connection) => {
  if (err) {
    console.error('Error connecting to the database:', err);
    return;
  }
  console.log('Successfully connected to the database');
  connection.release(); // Release the connection back to the pool
});

// Handle connection errors
pool.on('connection', function (connection) {
  console.log('New connection established as id ' + connection.threadId);
});

pool.on('error', function(err) {
  console.error('Database error:', err);
  if(err.code === 'PROTOCOL_CONNECTION_LOST') {
    console.log('Database connection was closed.');
  }
  if(err.code === 'ER_CON_COUNT_ERROR') {
    console.log('Database has too many connections.');
  }
  if(err.code === 'ECONNREFUSED') {
    console.log('Database connection was refused.');
  }
});

// Helper function to execute queries with better error handling
const executeQuery = async (query, params = []) => {
  try {
    const [results] = await pool.promise().execute(query, params);
    return results;
  } catch (error) {
    console.error('Database query error:', error);
    throw error;
  }
};

module.exports = { pool, executeQuery }; 