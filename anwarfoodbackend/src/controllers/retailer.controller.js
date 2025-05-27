const { pool: db } = require('../config/database');

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

const getRetailerByUserMobile = async (req, res) => {
  try {
    const userId = req.user.userId;

    // First, get the user's mobile number
    const [users] = await db.promise().query(`
      SELECT MOBILE FROM user_info 
      WHERE USER_ID = ? AND ISACTIVE = 'Y'
    `, [userId]);

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const userMobile = users[0].MOBILE;

    // Then, find the retailer with matching mobile number
    const [retailers] = await db.promise().query(`
      SELECT * FROM retailer_info 
      WHERE RET_MOBILE_NO = ? AND RET_DEL_STATUS = 'active'
    `, [userMobile]);

    if (retailers.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No retailer found with your mobile number'
      });
    }

    const retailer = retailers[0];
    const retailerMobile = retailer.RET_MOBILE_NO;

    // Get users with the same mobile number as the retailer
    const [retailerUsers] = await db.promise().query(`
      SELECT USER_ID FROM user_info 
      WHERE MOBILE = ? AND ISACTIVE = 'Y'
    `, [retailerMobile]);

    const userIds = retailerUsers.map(user => user.USER_ID);

    if (userIds.length === 0) {
      // No users found with retailer's mobile number, return empty data
      res.json({
        success: true,
        data: {
          retailer: retailer,
          sales_summary: {
            total_orders: 0,
            total_sales_amount: 0,
            total_items_sold: 0,
            average_order_value: 0
          },
          graph_data: {
            monthly_sales: [],
            daily_sales: []
          },
          top_products: [],
          recent_orders: []
        }
      });
      return;
    }

    // Get total sales data from orders table
    const [totalSales] = await db.promise().query(`
      SELECT 
        COUNT(*) as total_orders,
        COALESCE(SUM(ORDER_TOTAL), 0) as total_sales_amount,
        COALESCE(SUM(oi.total_quantity), 0) as total_items_sold,
        COALESCE(AVG(ORDER_TOTAL), 0) as average_order_value
      FROM orders o
      LEFT JOIN (
        SELECT ORDER_ID, SUM(QUANTITY) as total_quantity 
        FROM order_items 
        GROUP BY ORDER_ID
      ) oi ON o.ORDER_ID = oi.ORDER_ID
      WHERE o.USER_ID IN (${userIds.map(() => '?').join(',')}) 
        AND o.ORDER_STATUS != 'cancelled'
    `, userIds);

    // Get monthly sales data for graph (last 12 months)
    const [monthlySales] = await db.promise().query(`
      SELECT 
        DATE_FORMAT(CREATED_DATE, '%Y-%m') as month,
        COUNT(*) as orders_count,
        COALESCE(SUM(ORDER_TOTAL), 0) as sales_amount,
        COALESCE(SUM(oi.total_quantity), 0) as items_sold
      FROM orders o
      LEFT JOIN (
        SELECT ORDER_ID, SUM(QUANTITY) as total_quantity 
        FROM order_items 
        GROUP BY ORDER_ID
      ) oi ON o.ORDER_ID = oi.ORDER_ID
      WHERE o.USER_ID IN (${userIds.map(() => '?').join(',')})
        AND o.ORDER_STATUS != 'cancelled'
        AND o.CREATED_DATE >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
      GROUP BY DATE_FORMAT(CREATED_DATE, '%Y-%m')
      ORDER BY month ASC
    `, userIds);

    // Get daily sales data for the current month
    const [dailySales] = await db.promise().query(`
      SELECT 
        DATE(CREATED_DATE) as date,
        COUNT(*) as orders_count,
        COALESCE(SUM(ORDER_TOTAL), 0) as sales_amount,
        COALESCE(SUM(oi.total_quantity), 0) as items_sold
      FROM orders o
      LEFT JOIN (
        SELECT ORDER_ID, SUM(QUANTITY) as total_quantity 
        FROM order_items 
        GROUP BY ORDER_ID
      ) oi ON o.ORDER_ID = oi.ORDER_ID
      WHERE o.USER_ID IN (${userIds.map(() => '?').join(',')})
        AND o.ORDER_STATUS != 'cancelled'
        AND MONTH(CREATED_DATE) = MONTH(CURDATE())
        AND YEAR(CREATED_DATE) = YEAR(CURDATE())
      GROUP BY DATE(CREATED_DATE)
      ORDER BY date ASC
    `, userIds);

    // Get top selling products
    const [topProducts] = await db.promise().query(`
      SELECT 
        p.PROD_NAME as product_name,
        SUM(oi.QUANTITY) as total_quantity,
        SUM(oi.TOTAL_PRICE) as total_amount,
        COUNT(DISTINCT o.ORDER_ID) as order_count
      FROM orders o
      JOIN order_items oi ON o.ORDER_ID = oi.ORDER_ID
      JOIN product p ON oi.PROD_ID = p.PROD_ID
      WHERE o.USER_ID IN (${userIds.map(() => '?').join(',')})
        AND o.ORDER_STATUS != 'cancelled'
      GROUP BY oi.PROD_ID, p.PROD_NAME
      ORDER BY total_quantity DESC
      LIMIT 10
    `, userIds);

    // Get recent orders
    const [recentOrders] = await db.promise().query(`
      SELECT 
        o.ORDER_ID,
        o.ORDER_NUMBER,
        o.CREATED_DATE,
        u.USERNAME as customer_name,
        u.MOBILE as customer_mobile,
        o.ORDER_TOTAL,
        oi.total_quantity,
        o.ORDER_STATUS,
        o.PAYMENT_METHOD
      FROM orders o
      JOIN user_info u ON o.USER_ID = u.USER_ID
      LEFT JOIN (
        SELECT ORDER_ID, SUM(QUANTITY) as total_quantity 
        FROM order_items 
        GROUP BY ORDER_ID
      ) oi ON o.ORDER_ID = oi.ORDER_ID
      WHERE o.USER_ID IN (${userIds.map(() => '?').join(',')})
      ORDER BY o.CREATED_DATE DESC
      LIMIT 10
    `, userIds);

    res.json({
      success: true,
      data: {
        retailer: retailer,
        sales_summary: {
          total_orders: totalSales[0].total_orders,
          total_sales_amount: parseFloat(totalSales[0].total_sales_amount),
          total_items_sold: totalSales[0].total_items_sold,
          average_order_value: parseFloat(totalSales[0].average_order_value)
        },
        graph_data: {
          monthly_sales: monthlySales.map(row => ({
            month: row.month,
            orders_count: row.orders_count,
            sales_amount: parseFloat(row.sales_amount),
            items_sold: row.items_sold
          })),
          daily_sales: dailySales.map(row => ({
            date: row.date,
            orders_count: row.orders_count,
            sales_amount: parseFloat(row.sales_amount),
            items_sold: row.items_sold
          }))
        },
        top_products: topProducts.map(row => ({
          product_name: row.product_name,
          total_quantity: row.total_quantity,
          total_amount: parseFloat(row.total_amount),
          order_count: row.order_count
        })),
        recent_orders: recentOrders.map(row => ({
          order_id: row.ORDER_ID,
          order_number: row.ORDER_NUMBER,
          order_date: row.CREATED_DATE,
          customer_name: row.customer_name,
          customer_mobile: row.customer_mobile,
          total_amount: parseFloat(row.ORDER_TOTAL),
          total_quantity: row.total_quantity || 0,
          status: row.ORDER_STATUS,
          payment_mode: row.PAYMENT_METHOD
        }))
      }
    });
  } catch (error) {
    console.error('Error fetching retailer by user mobile:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching retailer information',
      error: error.message
    });
  }
};

module.exports = {
  getRetailerList,
  getRetailerInfo,
  getRetailerByUserMobile
}; 