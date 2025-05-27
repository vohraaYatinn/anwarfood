const mysql = require('mysql2');
require('dotenv').config();

const db = mysql.createConnection({
  host: 'sql12.freesqldatabase.com',
  user: 'sql12781540',
  password: 'rijjEPTqBB',
  database: 'sql12781540',
  port: 3306
});

db.connect((err) => {
  if (err) {
    console.error('Error connecting to the database:', err);
    return;
  }
  console.log('Successfully connected to the database');
});

module.exports = db; 