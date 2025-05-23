const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/database');

const signup = async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;
    
    // Check if user already exists
    const [existingUsers] = await db.query(
      'SELECT * FROM user_info WHERE EMAIL = ? OR MOBILE = ?',
      [email, phone]
    );

    if (existingUsers.length > 0) {
      return res.status(400).json({ message: 'User already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert new user
    const [result] = await db.query(
      'INSERT INTO user_info (USERNAME, EMAIL, MOBILE, PASSWORD, CREATED_DATE, ISACTIVE) VALUES (?, ?, ?, ?, NOW(), "Y")',
      [name, email, phone, hashedPassword]
    );

    res.status(201).json({ message: 'User created successfully', userId: result.insertId });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

const login = async (req, res) => {
  try {
    const { phone, password } = req.body;

    // Find user
    const [users] = await db.query(
      'SELECT * FROM user_info WHERE MOBILE = ?',
      [phone]
    );

    if (users.length === 0) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const user = users[0];

    // Verify password
    const validPassword = await bcrypt.compare(password, user.PASSWORD);
    if (!validPassword) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.USER_ID, email: user.EMAIL },
      process.env.JWT_SECRET || 'your_jwt_secret_key',
      { expiresIn: '24h' }
    );

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user.USER_ID,
        name: user.USERNAME,
        email: user.EMAIL,
        phone: user.MOBILE
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

module.exports = {
  signup,
  login
}; 