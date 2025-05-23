const db = require('../config/database');

const getRetailerList = async (req, res) => {
  try {
    const [retailers] = await db.query(
      'SELECT * FROM retailer_info WHERE RET_DEL_STATUS = "active"'
    );
    res.json(retailers);
  } catch (error) {
    console.error('Retailer list error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

const getRetailerDetails = async (req, res) => {
  try {
    const [retailers] = await db.query(
      'SELECT * FROM retailer_info WHERE RET_ID = ?',
      [req.params.id]
    );

    if (retailers.length === 0) {
      return res.status(404).json({ message: 'Retailer not found' });
    }

    res.json(retailers[0]);
  } catch (error) {
    console.error('Retailer details error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

module.exports = {
  getRetailerList,
  getRetailerDetails
}; 