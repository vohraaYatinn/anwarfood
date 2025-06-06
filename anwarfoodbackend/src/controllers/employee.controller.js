const { pool: db } = require('../config/database');

// Fetch all orders with status filtering
const fetchOrders = async (req, res) => {
  try {
    const { status, page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;

    let query = `
      SELECT 
        o.*,
        u.USERNAME as CUSTOMER_NAME,
        u.MOBILE as CUSTOMER_MOBILE,
        u.EMAIL as CUSTOMER_EMAIL
      FROM orders o
      JOIN user_info u ON o.USER_ID = u.USER_ID
      WHERE 1=1
    `;
    
    const queryParams = [];

    // Add status filter if provided
    if (status) {
      query += ` AND o.ORDER_STATUS = ?`;
      queryParams.push(status);
    }

    // Add sorting and pagination
    query += ` ORDER BY o.CREATED_DATE DESC LIMIT ? OFFSET ?`;
    queryParams.push(parseInt(limit), offset);

    // Get total count for pagination
    const [countResult] = await db.promise().query(
      `SELECT COUNT(*) as total FROM orders o WHERE 1=1 ${status ? 'AND o.ORDER_STATUS = ?' : ''}`,
      status ? [status] : []
    );

    const [orders] = await db.promise().query(query, queryParams);

    res.json({
      success: true,
      data: {
        orders,
        pagination: {
          total: countResult[0].total,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages: Math.ceil(countResult[0].total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Fetch orders error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching orders',
      error: error.message
    });
  }
};

// Search orders by ORDER_NUMBER or user's MOBILE
const searchOrders = async (req, res) => {
  try {
    const { query, page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;

    if (!query) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }

    const searchQuery = `
      SELECT 
        o.*,
        u.USERNAME as CUSTOMER_NAME,
        u.MOBILE as CUSTOMER_MOBILE,
        u.EMAIL as CUSTOMER_EMAIL
      FROM orders o
      JOIN user_info u ON o.USER_ID = u.USER_ID
      WHERE o.ORDER_NUMBER LIKE ? OR u.MOBILE LIKE ?
      ORDER BY 
        CASE 
          WHEN o.ORDER_NUMBER = ? THEN 1
          WHEN u.MOBILE = ? THEN 1
          WHEN o.ORDER_NUMBER LIKE ? THEN 2
          WHEN u.MOBILE LIKE ? THEN 2
          ELSE 3
        END,
        o.CREATED_DATE DESC
      LIMIT ? OFFSET ?
    `;

    // Get total count for pagination
    const [countResult] = await db.promise().query(
      `SELECT COUNT(*) as total 
       FROM orders o 
       JOIN user_info u ON o.USER_ID = u.USER_ID 
       WHERE o.ORDER_NUMBER LIKE ? OR u.MOBILE LIKE ?`,
      [`%${query}%`, `%${query}%`]
    );

    const [orders] = await db.promise().query(
      searchQuery,
      [
        `%${query}%`, `%${query}%`,
        query, query,
        `%${query}%`, `%${query}%`,
        parseInt(limit), offset
      ]
    );

    res.json({
      success: true,
      data: {
        orders,
        pagination: {
          total: countResult[0].total,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages: Math.ceil(countResult[0].total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Search orders error:', error);
    res.status(500).json({
      success: false,
      message: 'Error searching orders',
      error: error.message
    });
  }
};

// Get order details by ID
const getOrderDetails = async (req, res) => {
  try {
    const { orderId } = req.params;

    const [orders] = await db.promise().query(
      `SELECT 
        o.*,
        u.USERNAME as CUSTOMER_NAME,
        u.MOBILE as CUSTOMER_MOBILE,
        u.EMAIL as CUSTOMER_EMAIL
      FROM orders o
      JOIN user_info u ON o.USER_ID = u.USER_ID
      WHERE o.ORDER_ID = ?`,
      [orderId]
    );

    if (orders.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Get order items if needed
    const [orderItems] = await db.promise().query(
      `SELECT 
        oi.*,
        p.PROD_NAME,
        p.PROD_IMAGE_1,
        pu.PU_PROD_UNIT,
        pu.PU_PROD_UNIT_VALUE
      FROM order_items oi
      JOIN product p ON oi.PROD_ID = p.PROD_ID
      LEFT JOIN product_unit pu ON oi.UNIT_ID = pu.PU_ID
      WHERE oi.ORDER_ID = ?`,
      [orderId]
    );

    res.json({
      success: true,
      data: {
        ...orders[0],
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

// Update order status
const updateOrderStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status } = req.body;

    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Order status is required'
      });
    }

    // Validate status value
    const validStatuses = ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'];
    if (!validStatuses.includes(status.toLowerCase())) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status value. Valid values are: ' + validStatuses.join(', ')
      });
    }

    // First check if order exists
    const [orders] = await db.promise().query(
      'SELECT ORDER_ID, ORDER_STATUS FROM orders WHERE ORDER_ID = ?',
      [orderId]
    );

    if (orders.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Don't allow status change if order is already cancelled or delivered
    const currentStatus = orders[0].ORDER_STATUS.toLowerCase();
    if (currentStatus === 'cancelled' || currentStatus === 'delivered') {
      return res.status(400).json({
        success: false,
        message: `Cannot change status of ${currentStatus} order`
      });
    }

    // Update order status
    await db.promise().query(
      `UPDATE orders 
       SET ORDER_STATUS = ?, 
           UPDATED_DATE = NOW()
       WHERE ORDER_ID = ?`,
      [status.toLowerCase(), orderId]
    );

    res.json({
      success: true,
      message: 'Order status updated successfully',
      data: {
        orderId,
        oldStatus: currentStatus,
        newStatus: status.toLowerCase(),
        updatedAt: new Date()
      }
    });
  } catch (error) {
    console.error('Update order status error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating order status',
      error: error.message
    });
  }
};

module.exports = {
  fetchOrders,
  searchOrders,
  getOrderDetails,
  updateOrderStatus
}; 