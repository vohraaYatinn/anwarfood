const db = require('../config/database');

const getOrderList = async (req, res) => {
  try {
    const userId = req.user.userId;

    const [orders] = await db.promise().query(`
      SELECT co.*, 
             COUNT(cod.COD_ID) as total_items,
             SUM(cod.COD_QTY) as total_quantity
      FROM cust_order co
      LEFT JOIN cust_order_details cod ON co.CO_ID = cod.COD_CO_ID
      WHERE co.CO_CUST_CODE = (SELECT USERNAME FROM user_info WHERE USER_ID = ?)
      GROUP BY co.CO_ID
      ORDER BY co.CO_DATE DESC
    `, [userId]);

    res.json({
      success: true,
      data: orders
    });
  } catch (error) {
    console.error('Get order list error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching order list',
      error: error.message
    });
  }
};

const getOrderDetails = async (req, res) => {
  try {
    const { orderId } = req.params;
    const userId = req.user.userId;

    // Get order header
    const [orders] = await db.promise().query(`
      SELECT * FROM cust_order 
      WHERE CO_ID = ? AND CO_CUST_CODE = (SELECT USERNAME FROM user_info WHERE USER_ID = ?)
    `, [orderId, userId]);

    if (orders.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Get order details
    const [orderDetails] = await db.promise().query(`
      SELECT * FROM cust_order_details
      WHERE COD_CO_ID = ?
    `, [orderId]);

    // Get payment details
    const [payments] = await db.promise().query(`
      SELECT * FROM cust_payment
      WHERE PAYMENT_MERCHANT_REF_INVOICE_NO = ?
    `, [orders[0].CO_NO]);

    res.json({
      success: true,
      data: {
        order: orders[0],
        items: orderDetails,
        payment: payments[0] || null
      }
    });
  } catch (error) {
    console.error('Get order details error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching order details',
      error: error.message
    });
  }
};

module.exports = {
  getOrderList,
  getOrderDetails
}; 