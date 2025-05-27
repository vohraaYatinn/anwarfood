const { pool: db } = require('../config/database');

const getOrderList = async (req, res) => {
  try {
    const userId = req.user.userId;

    const [orders] = await db.promise().query(`
      SELECT o.*, 
             COUNT(oi.ORDER_ITEM_ID) as total_items,
             SUM(oi.QUANTITY) as total_quantity
      FROM orders o
      LEFT JOIN order_items oi ON o.ORDER_ID = oi.ORDER_ID
      WHERE o.USER_ID = ?
      GROUP BY o.ORDER_ID
      ORDER BY o.CREATED_DATE DESC
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
      SELECT * FROM orders 
      WHERE ORDER_ID = ? AND USER_ID = ?
    `, [orderId, userId]);

    if (orders.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Get order items with product details
    const [orderItems] = await db.promise().query(`
      SELECT oi.*, p.PROD_NAME, p.PROD_IMAGE_1,
             pu.PU_PROD_UNIT, pu.PU_PROD_UNIT_VALUE
      FROM order_items oi
      JOIN product p ON oi.PROD_ID = p.PROD_ID
      JOIN product_unit pu ON oi.UNIT_ID = pu.PU_ID
      WHERE oi.ORDER_ID = ?
    `, [orderId]);

    res.json({
      success: true,
      data: {
        order: orders[0],
        items: orderItems
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