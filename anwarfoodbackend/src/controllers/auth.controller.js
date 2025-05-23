const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/database');

const signup = async (req, res) => {
  try {
    const { username, email, password, mobile, city, province, zip, address } = req.body;

    // Check if user already exists
    const [existingUser] = await db.promise().query(
      'SELECT * FROM user_info WHERE EMAIL = ? OR MOBILE = ?',
      [email, mobile]
    );

    if (existingUser.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'User already exists with this email or mobile'
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert new user with UL_ID set to 1 (assuming 1 is a valid user level ID)
    const [result] = await db.promise().query(
      `INSERT INTO user_info (
        UL_ID, USERNAME, EMAIL, MOBILE, PASSWORD, CITY, PROVINCE, ZIP, ADDRESS, 
        CREATED_DATE, USER_TYPE, ISACTIVE
      ) VALUES (
        1, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), 'customer', 'Y'
      )`,
      [username, email, mobile, hashedPassword, city, province, zip, address]
    );

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      userId: result.insertId
    });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({
      success: false,
      message: 'Error in registration',
      error: error.message
    });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user
    const [users] = await db.promise().query(
      'SELECT * FROM user_info WHERE EMAIL = ?',
      [email]
    );

    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    const user = users[0];

    // Check password
    const isValidPassword = await bcrypt.compare(password, user.PASSWORD);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Generate token
    const token = jwt.sign(
      { userId: user.USER_ID, email: user.EMAIL },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    );

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        id: user.USER_ID,
        username: user.USERNAME,
        email: user.EMAIL,
        mobile: user.MOBILE
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Error in login',
      error: error.message
    });
  }
};

module.exports = {
  signup,
  login
}; 