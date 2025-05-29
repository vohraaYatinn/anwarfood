const jwt = require('jsonwebtoken');
const { pool: db } = require('../config/database');

const adminMiddleware = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
    
    // Fetch user details from database to check role
    const [users] = await db.promise().query(
      'SELECT USER_ID, EMAIL, USER_TYPE, ISACTIVE FROM user_info WHERE USER_ID = ?',
      [decoded.userId]
    );

    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'User not found'
      });
    }

    const user = users[0];

    // Check if user is active
    if (user.ISACTIVE !== 'Y') {
      return res.status(401).json({
        success: false,
        message: 'User account is inactive'
      });
    }

    // Check if user has admin role
    if (user.USER_TYPE !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Admin privileges required.'
      });
    }

    req.user = user;
    next();
  } catch (error) {
    console.error('Admin middleware error:', error);
    return res.status(401).json({
      success: false,
      message: 'Invalid token'
    });
  }
};

module.exports = adminMiddleware; 