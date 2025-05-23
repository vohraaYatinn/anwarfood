const db = require('../config/database');

const getOrderList = async (req, res) => {
  try {
    const [orders] = await db.query(
      'SELECT * FROM cust_order WHERE CO_CUST_CODE = ?',
      [req.params.userId]
    );
    res.json(orders);
  } catch (error) {
    console.error('Order list error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

module.exports = {
  getOrderList
}; 