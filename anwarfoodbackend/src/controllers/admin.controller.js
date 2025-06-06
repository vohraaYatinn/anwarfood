const { pool: db } = require('../config/database');
const bcrypt = require('bcryptjs');

// Product Management APIs
const addProduct = async (req, res) => {
  const connection = await db.promise().getConnection();
  
  try {
    await connection.beginTransaction();

    const {
      prodSubCatId,
      prodName,
      prodCode,
      prodDesc,
      prodMrp,
      prodSp,
      prodReorderLevel,
      prodQoh,
      prodHsnCode,
      prodCgst,
      prodIgst,
      prodSgst,
      prodMfgDate,
      prodExpiryDate,
      prodMfgBy,
      prodImage1,
      prodImage2,
      prodImage3,
      prodCatId,
      isBarcodeAvailable = 'N',
      productUnits = [] // Array of product units
    } = req.body;

    // Insert product first
    const [result] = await connection.query(
      `INSERT INTO product (
        PROD_SUB_CAT_ID, PROD_NAME, PROD_CODE, PROD_DESC, PROD_MRP, PROD_SP,
        PROD_REORDER_LEVEL, PROD_QOH, PROD_HSN_CODE, PROD_CGST, PROD_IGST, PROD_SGST,
        PROD_MFG_DATE, PROD_EXPIRY_DATE, PROD_MFG_BY, PROD_IMAGE_1, PROD_IMAGE_2,
        PROD_IMAGE_3, PROD_CAT_ID, IS_BARCODE_AVAILABLE, DEL_STATUS,
        CREATED_BY, UPDATED_BY, CREATED_DATE, UPDATED_DATE
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'N', ?, ?, NOW(), NOW())`,
      [
        prodSubCatId, prodName, prodCode, prodDesc, prodMrp, prodSp,
        prodReorderLevel, prodQoh, prodHsnCode, prodCgst, prodIgst, prodSgst,
        prodMfgDate, prodExpiryDate, prodMfgBy, prodImage1, prodImage2,
        prodImage3, prodCatId, isBarcodeAvailable,
        req.user.USERNAME, req.user.USERNAME
      ]
    );

    const productId = result.insertId;

    // Insert product units if provided
    if (productUnits && productUnits.length > 0) {
      const unitValues = productUnits.map(unit => [
        productId,
        unit.unitName,
        unit.unitValue,
        unit.unitRate,
        'A', // PU_STATUS - Active
        req.user.USERNAME,
        req.user.USERNAME,
        new Date(),
        new Date()
      ]);

      await connection.query(
        `INSERT INTO product_unit (
          PU_PROD_ID, PU_PROD_UNIT, PU_PROD_UNIT_VALUE, PU_PROD_RATE,
          PU_STATUS, CREATED_BY, UPDATED_BY, CREATED_DATE, UPDATED_DATE
        ) VALUES ?`,
        [unitValues]
      );
    }

    await connection.commit();

    res.status(201).json({
      success: true,
      message: 'Product and units added successfully',
      productId: productId
    });
  } catch (error) {
    await connection.rollback();
    console.error('Add product error:', error);
    res.status(500).json({
      success: false,
      message: 'Error adding product',
      error: error.message
    });
  } finally {
    connection.release();
  }
};

const editProduct = async (req, res) => {
  const connection = await db.promise().getConnection();
  
  try {
    await connection.beginTransaction();
    
    const { productId } = req.params;
    const {
      prodSubCatId,
      prodName,
      prodCode,
      prodDesc,
      prodMrp,
      prodSp,
      prodReorderLevel,
      prodQoh,
      prodHsnCode,
      prodCgst,
      prodIgst,
      prodSgst,
      prodMfgDate,
      prodExpiryDate,
      prodMfgBy,
      prodImage1,
      prodImage2,
      prodImage3,
      prodCatId,
      isBarcodeAvailable,
      productUnits = [] // Array of product units
    } = req.body;

    // First check if product exists
    const [existingProduct] = await connection.query(
      'SELECT PROD_ID FROM product WHERE PROD_ID = ?',
      [productId]
    );

    if (existingProduct.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    // Update product details
    const [result] = await connection.query(
      `UPDATE product SET 
        PROD_SUB_CAT_ID = ?, PROD_NAME = ?, PROD_CODE = ?, PROD_DESC = ?,
        PROD_MRP = ?, PROD_SP = ?, PROD_REORDER_LEVEL = ?, PROD_QOH = ?,
        PROD_HSN_CODE = ?, PROD_CGST = ?, PROD_IGST = ?, PROD_SGST = ?,
        PROD_MFG_DATE = ?, PROD_EXPIRY_DATE = ?, PROD_MFG_BY = ?,
        PROD_IMAGE_1 = ?, PROD_IMAGE_2 = ?, PROD_IMAGE_3 = ?,
        PROD_CAT_ID = ?, IS_BARCODE_AVAILABLE = ?, UPDATED_BY = ?, UPDATED_DATE = NOW()
      WHERE PROD_ID = ?`,
      [
        prodSubCatId, prodName, prodCode, prodDesc, prodMrp, prodSp,
        prodReorderLevel, prodQoh, prodHsnCode, prodCgst, prodIgst, prodSgst,
        prodMfgDate, prodExpiryDate, prodMfgBy, prodImage1, prodImage2,
        prodImage3, prodCatId, isBarcodeAvailable, req.user.USERNAME, productId
      ]
    );

    // Handle product units
    if (productUnits && productUnits.length > 0) {
      // Get existing units
      const [existingUnits] = await connection.query(
        'SELECT PU_ID, PU_PROD_UNIT as unitName, PU_PROD_UNIT_VALUE as unitValue, PU_PROD_RATE as unitRate, PU_STATUS as status FROM product_unit WHERE PU_PROD_ID = ?',
        [productId]
      );

      // Create a map of existing units for easy comparison
      const existingUnitsMap = new Map();
      existingUnits.forEach(unit => {
        const key = `${unit.unitName}-${unit.unitValue}-${unit.unitRate}`;
        existingUnitsMap.set(key, unit);
      });

      // Process each unit in the request
      for (const unit of productUnits) {
        const unitKey = `${unit.unitName}-${unit.unitValue}-${unit.unitRate}`;
        const existingUnit = existingUnitsMap.get(unitKey);

        if (existingUnit) {
          // Unit exists with same values, just ensure it's active
          if (existingUnit.status !== 'A') {
            await connection.query(
              `UPDATE product_unit 
               SET PU_STATUS = 'A',
                   UPDATED_BY = ?,
                   UPDATED_DATE = NOW()
               WHERE PU_ID = ?`,
              [req.user.USERNAME, existingUnit.PU_ID]
            );
          }
          // Remove from map to track which units were not in the request
          existingUnitsMap.delete(unitKey);
        } else {
          // Unit doesn't exist or has different values, create new one
          await connection.query(
            `INSERT INTO product_unit (
              PU_PROD_ID, PU_PROD_UNIT, PU_PROD_UNIT_VALUE, PU_PROD_RATE,
              PU_STATUS, CREATED_BY, UPDATED_BY, CREATED_DATE, UPDATED_DATE
            ) VALUES (?, ?, ?, ?, 'A', ?, ?, NOW(), NOW())`,
            [
              productId,
              unit.unitName,
              unit.unitValue,
              unit.unitRate,
              req.user.USERNAME,
              req.user.USERNAME
            ]
          );
        }
      }

      // Deactivate units that were not in the request
      if (existingUnitsMap.size > 0) {
        const unitsToDeactivate = Array.from(existingUnitsMap.values()).map(u => u.PU_ID);
        await connection.query(
          `UPDATE product_unit 
           SET PU_STATUS = 'I',
               UPDATED_BY = ?,
               UPDATED_DATE = NOW()
           WHERE PU_ID IN (?)`,
          [req.user.USERNAME, unitsToDeactivate]
        );
      }
    }

    await connection.commit();

    res.json({
      success: true,
      message: 'Product and units updated successfully'
    });
  } catch (error) {
    await connection.rollback();
    console.error('Edit product error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating product',
      error: error.message
    });
  } finally {
    connection.release();
  }
};

// Category Management APIs
const addCategory = async (req, res) => {
  try {
    const { categoryName, catImage } = req.body;

    const [result] = await db.promise().query(
      `INSERT INTO category (
        CATEGORY_NAME, CAT_IMAGE, DEL_STATUS, CREATED_BY, UPDATED_BY, CREATED_DATE, UPDATED_DATE
      ) VALUES (?, ?, 'N', ?, ?, NOW(), NOW())`,
      [categoryName, catImage, req.user.USERNAME, req.user.USERNAME]
    );

    res.status(201).json({
      success: true,
      message: 'Category added successfully',
      categoryId: result.insertId
    });
  } catch (error) {
    console.error('Add category error:', error);
    res.status(500).json({
      success: false,
      message: 'Error adding category',
      error: error.message
    });
  }
};

const editCategory = async (req, res) => {
  try {
    const { categoryId } = req.params;
    const { categoryName, catImage } = req.body;

    const [result] = await db.promise().query(
      `UPDATE category SET 
        CATEGORY_NAME = ?, CAT_IMAGE = ?, UPDATED_BY = ?, UPDATED_DATE = NOW()
      WHERE CATEGORY_ID = ?`,
      [categoryName, catImage, req.user.USERNAME, categoryId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }

    res.json({
      success: true,
      message: 'Category updated successfully'
    });
  } catch (error) {
    console.error('Edit category error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating category',
      error: error.message
    });
  }
};

// User Management APIs
const fetchUsers = async (req, res) => {
  try {
    const { page = 1, limit = 10, userType } = req.query;
    const offset = (page - 1) * limit;

    let whereClause = 'WHERE ISACTIVE = "Y"';
    let params = [];

    if (userType) {
      whereClause += ' AND USER_TYPE = ?';
      params.push(userType);
    }

    const [users] = await db.promise().query(
      `SELECT USER_ID, UL_ID, USERNAME, EMAIL, MOBILE, CITY, PROVINCE, ZIP, 
       ADDRESS, PHOTO, USER_TYPE, CREATED_DATE, UPDATED_DATE
       FROM user_info ${whereClause}
       ORDER BY CREATED_DATE DESC
       LIMIT ? OFFSET ?`,
      [...params, parseInt(limit), offset]
    );

    const [countResult] = await db.promise().query(
      `SELECT COUNT(*) as total FROM user_info ${whereClause}`,
      params
    );

    res.json({
      success: true,
      data: {
        users,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(countResult[0].total / limit),
          totalUsers: countResult[0].total,
          limit: parseInt(limit)
        }
      }
    });
  } catch (error) {
    console.error('Fetch users error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching users',
      error: error.message
    });
  }
};

const searchUsers = async (req, res) => {
  try {
    const { query, page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;

    if (!query) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }

    const searchPattern = `%${query}%`;
    const [users] = await db.promise().query(
      `SELECT USER_ID, UL_ID, USERNAME, EMAIL, MOBILE, CITY, PROVINCE, ZIP, 
       ADDRESS, PHOTO, USER_TYPE, CREATED_DATE, UPDATED_DATE
       FROM user_info 
       WHERE ISACTIVE = "Y" AND (
         USERNAME LIKE ? OR EMAIL LIKE ? OR MOBILE LIKE ?
       )
       ORDER BY CREATED_DATE DESC
       LIMIT ? OFFSET ?`,
      [searchPattern, searchPattern, searchPattern, parseInt(limit), offset]
    );

    res.json({
      success: true,
      data: users,
      searchQuery: query
    });
  } catch (error) {
    console.error('Search users error:', error);
    res.status(500).json({
      success: false,
      message: 'Error searching users',
      error: error.message
    });
  }
};

const editUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const {
      username,
      email,
      mobile,
      city,
      province,
      zip,
      address,
      userType,
      isActive
    } = req.body;

    // Check if user exists
    const [existingUser] = await db.promise().query(
      'SELECT USER_ID FROM user_info WHERE USER_ID = ?',
      [userId]
    );

    if (existingUser.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const [result] = await db.promise().query(
      `UPDATE user_info SET 
        USERNAME = ?, EMAIL = ?, MOBILE = ?, CITY = ?, PROVINCE = ?, ZIP = ?,
        ADDRESS = ?, USER_TYPE = ?, ISACTIVE = ?, UPDATED_BY = ?, UPDATED_DATE = NOW()
      WHERE USER_ID = ?`,
      [
        username, email, mobile, city, province, zip, address,
        userType, isActive, req.user.USERNAME, userId
      ]
    );

    res.json({
      success: true,
      message: 'User updated successfully'
    });
  } catch (error) {
    console.error('Edit user error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating user',
      error: error.message
    });
  }
};

// Order Management APIs
const fetchAllOrders = async (req, res) => {
  try {
    const { page = 1, limit = 20, status, startDate, endDate } = req.query;
    const offset = (page - 1) * limit;

    let whereClause = '';
    let params = [];

    const conditions = [];
    if (status) {
      conditions.push('o.ORDER_STATUS = ?');
      params.push(status);
    }
    if (startDate) {
      conditions.push('o.CREATED_DATE >= ?');
      params.push(startDate);
    }
    if (endDate) {
      conditions.push('o.CREATED_DATE <= ?');
      params.push(endDate);
    }

    if (conditions.length > 0) {
      whereClause = 'WHERE ' + conditions.join(' AND ');
    }

    // Fetch orders with user details and item count
    const [orders] = await db.promise().query(
      `SELECT 
        o.ORDER_ID, 
        o.ORDER_NUMBER, 
        o.USER_ID,
        o.ORDER_TOTAL, 
        o.ORDER_STATUS, 
        o.DELIVERY_ADDRESS,
        o.DELIVERY_CITY,
        o.DELIVERY_STATE,
        o.DELIVERY_COUNTRY,
        o.DELIVERY_PINCODE,
        o.DELIVERY_LANDMARK,
        o.PAYMENT_METHOD, 
        o.ORDER_NOTES,
        o.CREATED_DATE,
        o.UPDATED_DATE,
        u.USERNAME as CUSTOMER_NAME,
        u.EMAIL as CUSTOMER_EMAIL,
        u.MOBILE as CUSTOMER_MOBILE,
        COUNT(oi.ORDER_ITEM_ID) as TOTAL_ITEMS
       FROM orders o 
       LEFT JOIN user_info u ON o.USER_ID = u.USER_ID
       LEFT JOIN order_items oi ON o.ORDER_ID = oi.ORDER_ID
       ${whereClause}
       GROUP BY o.ORDER_ID
       ORDER BY o.CREATED_DATE DESC
       LIMIT ? OFFSET ?`,
      [...params, parseInt(limit), offset]
    );

    // Get total count for pagination
    const [countResult] = await db.promise().query(
      `SELECT COUNT(DISTINCT o.ORDER_ID) as total 
       FROM orders o 
       LEFT JOIN user_info u ON o.USER_ID = u.USER_ID
       ${whereClause}`,
      params
    );

    res.json({
      success: true,
      data: {
        orders,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(countResult[0].total / limit),
          totalOrders: countResult[0].total,
          limit: parseInt(limit)
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

const editOrderStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status, orderNotes } = req.body;

    // Check if order exists
    const [existingOrder] = await db.promise().query(
      'SELECT ORDER_ID FROM orders WHERE ORDER_ID = ?',
      [orderId]
    );

    if (existingOrder.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Validate status
    const validStatuses = ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'];
    if (status && !validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid order status. Valid statuses are: ' + validStatuses.join(', ')
      });
    }

    // Update order
    const [result] = await db.promise().query(
      `UPDATE orders SET 
        ORDER_STATUS = ?, 
        ORDER_NOTES = ?, 
        UPDATED_DATE = NOW()
      WHERE ORDER_ID = ?`,
      [status, orderNotes, orderId]
    );

    res.json({
      success: true,
      message: 'Order status updated successfully'
    });
  } catch (error) {
    console.error('Edit order status error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating order status',
      error: error.message
    });
  }
};

// Add new function to get order details with items
const getOrderDetails = async (req, res) => {
  try {
    const { orderId } = req.params;

    // Get order details
    const [orderResult] = await db.promise().query(
      `SELECT 
        o.ORDER_ID, 
        o.ORDER_NUMBER, 
        o.USER_ID,
        o.ORDER_TOTAL, 
        o.ORDER_STATUS, 
        o.DELIVERY_ADDRESS,
        o.DELIVERY_CITY,
        o.DELIVERY_STATE,
        o.DELIVERY_COUNTRY,
        o.DELIVERY_PINCODE,
        o.DELIVERY_LANDMARK,
        o.PAYMENT_METHOD, 
        o.ORDER_NOTES,
        o.CREATED_DATE,
        o.UPDATED_DATE,
        u.USERNAME as CUSTOMER_NAME,
        u.EMAIL as CUSTOMER_EMAIL,
        u.MOBILE as CUSTOMER_MOBILE,
        u.ADDRESS as CUSTOMER_ADDRESS
       FROM orders o 
       LEFT JOIN user_info u ON o.USER_ID = u.USER_ID
       WHERE o.ORDER_ID = ?`,
      [orderId]
    );

    if (orderResult.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Get order items
    const [orderItems] = await db.promise().query(
      `SELECT 
        oi.ORDER_ITEM_ID,
        oi.PROD_ID,
        oi.UNIT_ID,
        oi.QUANTITY,
        oi.UNIT_PRICE,
        oi.TOTAL_PRICE,
        p.PROD_NAME,
        p.PROD_CODE,
        p.PROD_DESC,
        p.PROD_IMAGE_1
       FROM order_items oi
       LEFT JOIN product p ON oi.PROD_ID = p.PROD_ID
       WHERE oi.ORDER_ID = ?`,
      [orderId]
    );

    const orderDetails = {
      ...orderResult[0],
      ORDER_ITEMS: orderItems
    };

    res.json({
      success: true,
      data: orderDetails
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

// Retailer Management APIs
const getAllRetailers = async (req, res) => {
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
       RET_ADDRESS, RET_PIN_CODE,RET_PHOTO, RET_EMAIL_ID, RET_COUNTRY, RET_STATE, RET_CITY,
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

const addRetailer = async (req, res) => {
  try {
    const {
      retCode,
      retType,
      retName,
      retShopName,
      retMobileNo,
      retAddress,
      retPinCode,
      retEmailId,
      retPhoto,
      retCountry,
      retState,
      retCity,
      retGstNo,
      retLat,
      retLong
    } = req.body;

    const [result] = await db.promise().query(
      `INSERT INTO retailer_info (
        RET_CODE, RET_TYPE, RET_NAME, RET_SHOP_NAME, RET_MOBILE_NO, RET_ADDRESS,
        RET_PIN_CODE, RET_EMAIL_ID, RET_PHOTO, RET_COUNTRY, RET_STATE, RET_CITY,
        RET_GST_NO, RET_LAT, RET_LONG, RET_DEL_STATUS, CREATED_DATE, UPDATED_DATE,
        CREATED_BY, UPDATED_BY
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', NOW(), NOW(), ?, ?)`,
      [
        retCode, retType, retName, retShopName, retMobileNo, retAddress,
        retPinCode, retEmailId, retPhoto, retCountry, retState, retCity,
        retGstNo, retLat, retLong, req.user.USERNAME, req.user.USERNAME
      ]
    );

    res.status(201).json({
      success: true,
      message: 'Retailer added successfully',
      retailerId: result.insertId
    });
  } catch (error) {
    console.error('Add retailer error:', error);
    res.status(500).json({
      success: false,
      message: 'Error adding retailer',
      error: error.message
    });
  }
};

const editRetailer = async (req, res) => {
  try {
    const { retailerId } = req.params;
    const {
      retCode,
      retType,
      retName,
      retShopName,
      retMobileNo,
      retAddress,
      retPinCode,
      retEmailId,
      retPhoto,
      retCountry,
      retState,
      retCity,
      retGstNo,
      retLat,
      retLong,
      retDelStatus,
      shopOpenStatus
    } = req.body;

    const [result] = await db.promise().query(
      `UPDATE retailer_info SET 
        RET_CODE = ?, RET_TYPE = ?, RET_NAME = ?, RET_SHOP_NAME = ?, RET_MOBILE_NO = ?,
        RET_ADDRESS = ?, RET_PIN_CODE = ?, RET_EMAIL_ID = ?, RET_PHOTO = ?,
        RET_COUNTRY = ?, RET_STATE = ?, RET_CITY = ?, RET_GST_NO = ?,
        RET_LAT = ?, RET_LONG = ?, RET_DEL_STATUS = ?, SHOP_OPEN_STATUS = ?,
        UPDATED_BY = ?, UPDATED_DATE = NOW()
      WHERE RET_ID = ?`,
      [
        retCode, retType, retName, retShopName, retMobileNo, retAddress,
        retPinCode, retEmailId, retPhoto, retCountry, retState, retCity,
        retGstNo, retLat, retLong, retDelStatus, shopOpenStatus,
        req.user.USERNAME, retailerId
      ]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Retailer not found'
      });
    }

    res.json({
      success: true,
      message: 'Retailer updated successfully'
    });
  } catch (error) {
    console.error('Edit retailer error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating retailer',
      error: error.message
    });
  }
};

const getSingleRetailer = async (req, res) => {
  try {
    const { retailerId } = req.params;

    const [retailers] = await db.promise().query(
      `SELECT * FROM retailer_info WHERE RET_ID = ?`,
      [retailerId]
    );

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
    console.error('Get single retailer error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching retailer details',
      error: error.message
    });
  }
};

// Add admin search orders function
const searchOrders = async (req, res) => {
  try {
    const { query } = req.query;

    if (!query) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }

    // Search orders by order number or user mobile
    const [orders] = await db.promise().query(`
      SELECT DISTINCT
        o.ORDER_ID, 
        o.ORDER_NUMBER, 
        o.USER_ID,
        o.ORDER_TOTAL, 
        o.ORDER_STATUS, 
        o.DELIVERY_ADDRESS,
        o.DELIVERY_CITY,
        o.DELIVERY_STATE,
        o.PAYMENT_METHOD,
        o.CREATED_DATE,
        u.USERNAME as CUSTOMER_NAME,
        u.EMAIL as CUSTOMER_EMAIL,
        u.MOBILE as CUSTOMER_MOBILE,
        COUNT(oi.ORDER_ITEM_ID) as TOTAL_ITEMS,
        SUM(oi.QUANTITY) as TOTAL_QUANTITY
      FROM orders o 
      LEFT JOIN user_info u ON o.USER_ID = u.USER_ID
      LEFT JOIN order_items oi ON o.ORDER_ID = oi.ORDER_ID
      WHERE o.ORDER_NUMBER LIKE ? 
         OR u.MOBILE LIKE ?
      GROUP BY o.ORDER_ID
      ORDER BY 
        CASE 
          WHEN o.ORDER_NUMBER = ? THEN 1
          WHEN u.MOBILE = ? THEN 1
          WHEN o.ORDER_NUMBER LIKE ? THEN 2
          WHEN u.MOBILE LIKE ? THEN 2
          ELSE 3
        END,
        o.CREATED_DATE DESC
      LIMIT 50
    `, [`%${query}%`, `%${query}%`, query, query, `${query}%`, `${query}%`]);

    res.json({
      success: true,
      data: orders,
      count: orders.length,
      filters: {
        query: query
      }
    });
  } catch (error) {
    console.error('Admin search orders error:', error);
    res.status(500).json({
      success: false,
      message: 'Error searching orders',
      error: error.message
    });
  }
};

// Fetch all users with USER_TYPE employee
const fetchEmployees = async (req, res) => {
  try {
    const [employees] = await db.promise().query(
      `SELECT USER_ID, USERNAME, EMAIL, MOBILE, CITY, PROVINCE, ADDRESS, 
      CREATED_DATE, UPDATED_DATE, USER_TYPE, ISACTIVE 
      FROM user_info 
      WHERE USER_TYPE = 'employee' AND ISACTIVE = 'Y'
      ORDER BY CREATED_DATE DESC`
    );

    res.status(200).json({
      success: true,
      data: employees,
      message: 'Employees fetched successfully'
    });
  } catch (error) {
    console.error('Fetch employees error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching employees',
      error: error.message
    });
  }
};

// Fetch all orders created by a specific employee
const fetchEmployeeOrders = async (req, res) => {
  try {
    const { employeeId } = req.params;
    console.log(employeeId);
    // First verify if the user is an employee
    const [employee] = await db.promise().query(
      `SELECT USER_ID, USER_TYPE 
      FROM user_info 
      WHERE USER_ID = ? AND USER_TYPE = 'employee' AND ISACTIVE = 'Y'`,
      [employeeId]
    );

    if (employee.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Employee not found or inactive'
      });
    }

    // Fetch all orders created by the employee
    const [orders] = await db.promise().query(
      `SELECT o.*, u.USERNAME as CUSTOMER_NAME, u.EMAIL as CUSTOMER_EMAIL, u.MOBILE as CUSTOMER_MOBILE
      FROM orders o
      JOIN user_info u ON o.USER_ID = u.USER_ID
      WHERE o.CREATED_BY = ?
      ORDER BY o.CREATED_DATE DESC`,
      [employeeId]
    );

    res.status(200).json({
      success: true,
      data: orders,
      message: 'Employee orders fetched successfully'
    });
  } catch (error) {
    console.error('Fetch employee orders error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching employee orders',
      error: error.message
    });
  }
};

module.exports = {
  addProduct,
  editProduct,
  addCategory,
  editCategory,
  fetchUsers,
  searchUsers,
  editUser,
  fetchAllOrders,
  editOrderStatus,
  getAllRetailers,
  addRetailer,
  editRetailer,
  getSingleRetailer,
  getOrderDetails,
  searchOrders,
  fetchEmployees,
  fetchEmployeeOrders
}; 