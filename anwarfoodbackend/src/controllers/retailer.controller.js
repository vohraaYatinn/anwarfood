const db = require('../config/database');

const getRetailerList = async (req, res) => {
  try {
    const [retailers] = await db.promise().query(`
      SELECT RET_ID, RET_CODE, RET_NAME, RET_SHOP_NAME, RET_MOBILE_NO, 
             RET_ADDRESS, RET_CITY, RET_STATE, RET_PIN_CODE, RET_PHOTO,
             SHOP_OPEN_STATUS
      FROM retailer_info 
      WHERE RET_DEL_STATUS = 'active'
    `);

    res.json({
      success: true,
      data: retailers
    });
  } catch (error) {
    console.error('Error fetching retailer list:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching retailer list',
      error: error.message
    });
  }
};

const getRetailerInfo = async (req, res) => {
  try {
    const { retailerId } = req.params;

    const [retailers] = await db.promise().query(`
      SELECT * FROM retailer_info 
      WHERE RET_ID = ? AND RET_DEL_STATUS = 'active'
    `, [retailerId]);

    if (retailers.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Retailer not found'
      });
    }

    res.json({
      success: true,
      data: retailers[0]
    });
  } catch (error) {
    console.error('Error fetching retailer info:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching retailer info',
      error: error.message
    });
  }
};

module.exports = {
  getRetailerList,
  getRetailerInfo
}; 