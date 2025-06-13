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
      'SELECT ORDER_ID, ORDER_STATUS, PAYMENT_IMAGE FROM orders WHERE ORDER_ID = ?',
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

    // Get uploaded image filename if present
    const paymentImage = req.uploadedFile ? req.uploadedFile.filename : orders[0].PAYMENT_IMAGE;

    // Update order status and payment image
    await db.promise().query(
      `UPDATE orders 
       SET ORDER_STATUS = ?, 
           PAYMENT_IMAGE = ?,
           UPDATED_DATE = NOW()
       WHERE ORDER_ID = ?`,
      [status.toLowerCase(), paymentImage, orderId]
    );

    // If status is delivered, generate invoice PDF and QR code, and insert into invoice_master and invoice_detail
    if (status.toLowerCase() === 'delivered') {
      const [orderDetails] = await db.promise().query(
        `SELECT o.*, u.USERNAME, u.MOBILE, u.EMAIL, u.ADDRESS as USER_ADDRESS, u.CITY, u.PROVINCE, u.ZIP
         FROM orders o
         JOIN user_info u ON o.USER_ID = u.USER_ID
         WHERE o.ORDER_ID = ?`,
        [orderId]
      );
      const order = orderDetails[0];
      const [orderItems] = await db.promise().query(
        `SELECT oi.*, p.PROD_NAME, p.PROD_CODE, p.PROD_HSN_CODE, p.PROD_MRP, p.PROD_SP, p.PROD_IMAGE_1, p.PROD_IMAGE_2, p.PROD_IMAGE_3, pu.PU_PROD_UNIT
         FROM order_items oi
         JOIN product p ON oi.PROD_ID = p.PROD_ID
         JOIN product_unit pu ON oi.UNIT_ID = pu.PU_ID
         WHERE oi.ORDER_ID = ?`,
        [orderId]
      );
      // Generate invoice number (e.g., INV + orderId)
      const invoiceNumber = `INV${orderId}`;
      // Generate PDF and QR code
      const invoicePath = await require('../utils/invoiceGenerator').generateInvoicePDF({ order, orderItems, invoiceNumber });
      // Insert into invoice_master
      const [invoiceResult] = await db.promise().query(
        `INSERT INTO invoice_master (
          INVM_NO, INVM_TRANS_ID, INVM_DATE, INVM_CUST_ID, INVM_CUST_NAME, INVM_CUST_ADDRESS, INVM_CUST_MOBILE, INVM_CUST_GST,
          INVM_TOT_CGST, INVM_TOT_SGST, INVM_TOT_IGST, INVM_TOT_DISCOUNT_AMOUNT, INVM_TOT_TAX_AMOUNT, INVM_TOT_AMOUNT, INVM_TOT_NET_PAYABLE,
          INVM_STATUS, INVM_PAYMENT_MODE, CREATED_BY, UPDATED_BY, CREATED_DATE, UPDATED_DATE
        ) VALUES (?, ?, NOW(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
        [
          invoiceNumber,
          `TR${orderId}`,
          order.USER_ID,
          order.USERNAME,
          order.USER_ADDRESS || order.DELIVERY_ADDRESS,
          order.MOBILE,
          '', // INVM_CUST_GST
          0, // INVM_TOT_CGST
          0, // INVM_TOT_SGST
          0, // INVM_TOT_IGST
          0, // INVM_TOT_DISCOUNT_AMOUNT
          0, // INVM_TOT_TAX_AMOUNT
          order.ORDER_TOTAL,
          order.ORDER_TOTAL,
          'active',
          'cod',
          req.user.USERNAME || 'system',
          req.user.USERNAME || 'system'
        ]
      );
      const invoiceId = invoiceResult.insertId;
      // Insert into invoice_detail for each item
      for (const item of orderItems) {
        await db.promise().query(
          `INSERT INTO invoice_detail (INVD_INVM_ID, INVD_PROD_ID, INVD_PROD_CODE, INVD_PROD_NAME, INVD_PROD_UNIT, INVD_QTY, INVD_HSN_CODE, INVD_MRP, INVD_SP, INVD_DISCOUNT_PERCENTAGE, INVD_DISCOUNT_AMOUNT, INVD_CGST, INVD_SGST, INVD_IGST, INVD_PROD_IMAGE_1, INVD_PROD_IMAGE_2, INVD_PROD_IMAGE_3, INVD_TAMOUNT, INVD_PROD_STATUS, CREATED_BY, UPDATED_BY, CREATED_DATE, UPDATED_DATE)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 0, 0, 0, ?, ?, ?, ?, 'A', ?, ?, NOW(), NOW())`,
          [invoiceId, item.PROD_ID, item.PROD_CODE, item.PROD_NAME, item.PU_PROD_UNIT, item.QUANTITY, item.PROD_HSN_CODE, item.PROD_MRP, item.PROD_SP, item.PROD_IMAGE_1, item.PROD_IMAGE_2, item.PROD_IMAGE_3, item.TOTAL_PRICE, req.user.USERNAME || 'system', req.user.USERNAME || 'system']
        );
      }
      // Update the orders table with the invoice URL
      await db.promise().query(
        'UPDATE orders SET INVOICE_URL = ? WHERE ORDER_ID = ?',
        [`/uploads/invoice/${invoiceNumber}.pdf`, orderId]
      );
    }

    res.json({
      success: true,
      message: 'Order status updated successfully',
      data: {
        orderId,
        oldStatus: currentStatus,
        newStatus: status.toLowerCase(),
        paymentImage: paymentImage ? `/uploads/orders/${paymentImage}` : null,
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

// Place order on behalf of retailer/customer using employee's cart
const placeOrderForCustomer = async (req, res) => {
  const connection = await db.promise().getConnection();
  
  try {
    await connection.beginTransaction();
    
    const { phoneNumber, notes } = req.body;
    const employeeUserId = req.user.USER_ID; // Get employee user ID from JWT token

    if (!phoneNumber) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }

    // Find retailer/customer by phone number using user_info table
    const [retailers] = await connection.query(
      `SELECT USER_ID, USERNAME, EMAIL, MOBILE, CITY, PROVINCE, ZIP, ADDRESS, USER_TYPE, ISACTIVE 
       FROM user_info 
       WHERE MOBILE = ? AND ISACTIVE = "Y"`,
      [phoneNumber]
    );

    if (retailers.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        success: false,
        message: 'Retailer/Customer not found with this phone number'
      });
    }

    const retailer = retailers[0];
    const retailerUserId = retailer.USER_ID;

    // Get employee's cart items (employee who is logged in)
    const [cartItems] = await connection.query(`
      SELECT c.*, p.PROD_NAME, p.PROD_MRP, p.PROD_SP,
             pu.PU_PROD_UNIT, pu.PU_PROD_UNIT_VALUE, pu.PU_PROD_RATE
      FROM cart c
      JOIN product p ON c.PROD_ID = p.PROD_ID
      JOIN product_unit pu ON c.UNIT_ID = pu.PU_ID
      WHERE c.USER_ID = ?
    `, [employeeUserId]);

    if (cartItems.length === 0) {
      await connection.rollback();
      return res.status(400).json({
        success: false,
        message: 'Employee cart is empty. Please add items to cart first.'
      });
    }

    // Get default address for the retailer/customer
    const [defaultAddress] = await connection.query(
      `SELECT ADDRESS_ID, USER_ID, ADDRESS, CITY, STATE, COUNTRY, PINCODE, LANDMARK, ADDRESS_TYPE, IS_DEFAULT
       FROM customer_address 
       WHERE USER_ID = ? AND IS_DEFAULT = 1 AND DEL_STATUS != "Y" 
       LIMIT 1`,
      [retailerUserId]
    );
    
    // If no default address found, use retailer's info from user_info table
    let orderAddress = null;
    if (defaultAddress.length === 0) {
      // Create a default address object from user_info data
      orderAddress = {
        ADDRESS_ID: null,
        ADDRESS: retailer.ADDRESS || 'Address not provided',
        CITY: retailer.CITY || 'City not provided',
        STATE: retailer.PROVINCE || 'State not provided',
        COUNTRY: 'India', // Default country
        PINCODE: retailer.ZIP || '000000',
        LANDMARK: null,
        ADDRESS_TYPE: 'Home'
      };
    } else {
      orderAddress = defaultAddress[0];
    }

    // Calculate order total
    const orderTotal = cartItems.reduce((total, item) => {
      return total + (item.PU_PROD_RATE * item.QUANTITY);
    }, 0);

    // Generate order number
    const orderNumber = 'EMP-ORD-' + Date.now();

    // Create order with retailer as USER_ID and force payment method to COD only
    const [orderResult] = await connection.query(`
      INSERT INTO orders (
        ORDER_NUMBER, USER_ID, ORDER_TOTAL, ORDER_STATUS, 
        DELIVERY_ADDRESS, DELIVERY_CITY, DELIVERY_STATE, 
        DELIVERY_COUNTRY, DELIVERY_PINCODE, DELIVERY_LANDMARK,
        PAYMENT_METHOD, ORDER_NOTES
      ) VALUES (?, ?, ?, 'pending', ?, ?, ?, ?, ?, ?, ?, ?)
    `, [
      orderNumber, retailerUserId, orderTotal, 
      orderAddress.ADDRESS, orderAddress.CITY, orderAddress.STATE,
      orderAddress.COUNTRY, orderAddress.PINCODE, orderAddress.LANDMARK,
      'cod', // Force COD payment method
      notes || 'Order placed by employee on behalf of retailer/customer'
    ]);

    const orderId = orderResult.insertId;

    // Create order items
    for (const item of cartItems) {
      await connection.query(`
        INSERT INTO order_items (
          ORDER_ID, PROD_ID, UNIT_ID, QUANTITY, 
          UNIT_PRICE, TOTAL_PRICE, CREATED_DATE
        ) VALUES (?, ?, ?, ?, ?, ?, NOW())
      `, [
        orderId, item.PROD_ID, item.UNIT_ID, item.QUANTITY,
        item.PU_PROD_RATE, (item.PU_PROD_RATE * item.QUANTITY)
      ]);
    }

    // Clear employee's cart
    await connection.query('DELETE FROM cart WHERE USER_ID = ?', [employeeUserId]);

    // Generate invoice immediately after order creation
    const [orderDetails] = await connection.query(
      `SELECT o.*, u.USERNAME, u.MOBILE, u.EMAIL, u.ADDRESS as USER_ADDRESS, u.CITY, u.PROVINCE, u.ZIP
       FROM orders o
       JOIN user_info u ON o.USER_ID = u.USER_ID
       WHERE o.ORDER_ID = ?`,
      [orderId]
    );
    const order = orderDetails[0];
    const [orderItems] = await connection.query(
      `SELECT oi.*, p.PROD_NAME, p.PROD_CODE, p.PROD_HSN_CODE, p.PROD_MRP, p.PROD_SP, p.PROD_IMAGE_1, p.PROD_IMAGE_2, p.PROD_IMAGE_3, pu.PU_PROD_UNIT
       FROM order_items oi
       JOIN product p ON oi.PROD_ID = p.PROD_ID
       JOIN product_unit pu ON oi.UNIT_ID = pu.PU_ID
       WHERE oi.ORDER_ID = ?`,
      [orderId]
    );
    // Generate invoice number
    const invoiceNumber = `INV${orderId}`;
    // Generate PDF and QR code
    const invoicePath = await require('../utils/invoiceGenerator').generateInvoicePDF({ order, orderItems, invoiceNumber });
    // Insert into invoice_master
    const [invoiceResult] = await connection.query(
      `INSERT INTO invoice_master (
        INVM_NO, INVM_TRANS_ID, INVM_DATE, INVM_CUST_ID, INVM_CUST_NAME, INVM_CUST_ADDRESS, INVM_CUST_MOBILE, INVM_CUST_GST,
        INVM_TOT_CGST, INVM_TOT_SGST, INVM_TOT_IGST, INVM_TOT_DISCOUNT_AMOUNT, INVM_TOT_TAX_AMOUNT, INVM_TOT_AMOUNT, INVM_TOT_NET_PAYABLE,
        INVM_STATUS, INVM_PAYMENT_MODE, CREATED_BY, UPDATED_BY, CREATED_DATE, UPDATED_DATE
      ) VALUES (?, ?, NOW(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
      [
        invoiceNumber,
        `TR${orderId}`,
        order.USER_ID,
        order.USERNAME,
        order.USER_ADDRESS || order.DELIVERY_ADDRESS,
        order.MOBILE,
        '', // INVM_CUST_GST
        0, // INVM_TOT_CGST
        0, // INVM_TOT_SGST
        0, // INVM_TOT_IGST
        0, // INVM_TOT_DISCOUNT_AMOUNT
        0, // INVM_TOT_TAX_AMOUNT
        order.ORDER_TOTAL,
        order.ORDER_TOTAL,
        'active',
        'cod',
        req.user.USERNAME || 'system',
        req.user.USERNAME || 'system'
      ]
    );
    const invoiceId = invoiceResult.insertId;
    // Insert into invoice_detail for each item
    for (const item of orderItems) {
      await connection.query(
        `INSERT INTO invoice_detail (INVD_INVM_ID, INVD_PROD_ID, INVD_PROD_CODE, INVD_PROD_NAME, INVD_PROD_UNIT, INVD_QTY, INVD_HSN_CODE, INVD_MRP, INVD_SP, INVD_DISCOUNT_PERCENTAGE, INVD_DISCOUNT_AMOUNT, INVD_CGST, INVD_SGST, INVD_IGST, INVD_PROD_IMAGE_1, INVD_PROD_IMAGE_2, INVD_PROD_IMAGE_3, INVD_TAMOUNT, INVD_PROD_STATUS, CREATED_BY, UPDATED_BY, CREATED_DATE, UPDATED_DATE)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 0, 0, 0, ?, ?, ?, ?, 'A', ?, ?, NOW(), NOW())`,
        [invoiceId, item.PROD_ID, item.PROD_CODE, item.PROD_NAME, item.PU_PROD_UNIT, item.QUANTITY, item.PROD_HSN_CODE, item.PROD_MRP, item.PROD_SP, item.PROD_IMAGE_1, item.PROD_IMAGE_2, item.PROD_IMAGE_3, item.TOTAL_PRICE, req.user.USERNAME || 'system', req.user.USERNAME || 'system']
      );
    }
    // Update the orders table with the invoice URL
    await connection.query(
      'UPDATE orders SET INVOICE_URL = ? WHERE ORDER_ID = ?',
      [`/uploads/invoice/${invoiceNumber}.pdf`, orderId]
    );

    // Commit transaction
    await connection.commit();

    res.json({
      success: true,
      message: 'Order placed successfully',
      data: {
        orderId,
        orderNumber,
        orderTotal,
        invoiceNumber,
        invoicePath: `/uploads/invoice/${invoiceNumber}.pdf`
      }
    });

  } catch (error) {
    await connection.rollback();
    console.error('Place order for retailer/customer error:', error);
    res.status(500).json({
      success: false,
      message: 'Error placing order for retailer/customer',
      error: error.message
    });
  } finally {
    connection.release();
  }
};

// Get all retailers with pagination and status filtering
const getRetailerList = async (req, res) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const offset = (page - 1) * limit;

    let whereClause = '';
    let params = [];

    if (status) {
      whereClause = 'WHERE RET_DEL_STATUS = ?';
      params.push(status);
    }

    const [retailers] = await db.promise().query(
      `SELECT RET_ID, RET_CODE, RET_TYPE, RET_NAME, RET_SHOP_NAME, RET_MOBILE_NO,
       RET_ADDRESS, RET_PIN_CODE, RET_PHOTO, RET_EMAIL_ID, RET_COUNTRY, RET_STATE, RET_CITY,
       RET_GST_NO, RET_DEL_STATUS, SHOP_OPEN_STATUS, CREATED_DATE
       FROM retailer_info ${whereClause}
       ORDER BY CREATED_DATE DESC
       LIMIT ? OFFSET ?`,
      [...params, parseInt(limit), offset]
    );

    const [countResult] = await db.promise().query(
      `SELECT COUNT(*) as total FROM retailer_info ${whereClause}`,
      params
    );

    res.json({
      success: true,
      data: {
        retailers,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(countResult[0].total / limit),
          totalRetailers: countResult[0].total,
          limit: parseInt(limit)
        }
      }
    });
  } catch (error) {
    console.error('Get retailers error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching retailers',
      error: error.message
    });
  }
};

// Search retailers by code, shop name, or mobile number
const searchRetailers = async (req, res) => {
  try {
    const { query } = req.query;
    
    if (!query) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }

    const [retailers] = await db.promise().query(`
      SELECT RET_ID, RET_CODE, RET_NAME, RET_SHOP_NAME, RET_MOBILE_NO, 
             RET_PHOTO, RET_ADDRESS, RET_CITY, RET_STATE, RET_DEL_STATUS, 
             SHOP_OPEN_STATUS, CREATED_DATE
      FROM retailer_info 
      WHERE RET_DEL_STATUS = 'active'
      AND (
        RET_CODE LIKE ? OR
        RET_SHOP_NAME LIKE ? OR
        RET_NAME LIKE ? OR
        RET_MOBILE_NO LIKE ?
      )
      ORDER BY 
        CASE 
          WHEN RET_CODE = ? THEN 1
          WHEN RET_SHOP_NAME LIKE ? THEN 2
          WHEN RET_NAME LIKE ? THEN 3
          WHEN RET_MOBILE_NO = ? THEN 4
          ELSE 5
        END,
        RET_SHOP_NAME ASC
    `, [
      `%${query}%`, `%${query}%`, `%${query}%`, `%${query}%`,
      query, `${query}%`, `${query}%`, query
    ]);

    res.json({
      success: true,
      data: retailers,
      count: retailers.length,
      filters: {
        query: query
      }
    });

  } catch (error) {
    console.error('Error in searchRetailers:', error);
    res.status(500).json({
      success: false,
      message: 'Error searching retailers',
      error: error.message
    });
  }
};

module.exports = {
  fetchOrders,
  searchOrders,
  getOrderDetails,
  updateOrderStatus,
  placeOrderForCustomer,
  getRetailerList,
  searchRetailers
}; 