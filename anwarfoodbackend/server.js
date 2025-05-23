const express = require('express');
const cors = require('cors');
const mysql = require('mysql2');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Database connection
const db = mysql.createConnection({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'shoppurs'
});

db.connect((err) => {
  if (err) {
    console.error('Error connecting to database:', err);
    return;
  }
  console.log('Connected to MySQL database');
});

// Routes
// Signup endpoint
app.post('/signup', async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;
    
    // Check if user already exists
    const [existingUsers] = await db.promise().query(
      'SELECT * FROM user_info WHERE EMAIL = ? OR MOBILE = ?',
      [email, phone]
    );

    if (existingUsers.length > 0) {
      return res.status(400).json({ message: 'User already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert new user
    const [result] = await db.promise().query(
      'INSERT INTO user_info (USERNAME, EMAIL, MOBILE, PASSWORD, CREATED_DATE, ISACTIVE) VALUES (?, ?, ?, ?, NOW(), "Y")',
      [name, email, phone, hashedPassword]
    );

    res.status(201).json({ message: 'User created successfully', userId: result.insertId });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Login endpoint
app.post('/login', async (req, res) => {
  try {
    const { phone, password } = req.body;

    // Find user
    const [users] = await db.promise().query(
      'SELECT * FROM user_info WHERE MOBILE = ?',
      [phone]
    );

    if (users.length === 0) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const user = users[0];

    // Verify password
    const validPassword = await bcrypt.compare(password, user.PASSWORD);
    if (!validPassword) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.USER_ID, email: user.EMAIL },
      process.env.JWT_SECRET || 'your_jwt_secret_key',
      { expiresIn: '24h' }
    );

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user.USER_ID,
        name: user.USERNAME,
        email: user.EMAIL,
        phone: user.MOBILE
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Product list endpoint
app.get('/productlist', async (req, res) => {
  try {
    const [products] = await db.promise().query(
      'SELECT * FROM product WHERE DEL_STATUS IS NULL OR DEL_STATUS != "Y"'
    );
    res.json(products);
  } catch (error) {
    console.error('Product list error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Product detail endpoint
app.get('/productdetail/:id', async (req, res) => {
  try {
    const [products] = await db.promise().query(
      'SELECT * FROM product WHERE PROD_ID = ?',
      [req.params.id]
    );

    if (products.length === 0) {
      return res.status(404).json({ message: 'Product not found' });
    }

    res.json(products[0]);
  } catch (error) {
    console.error('Product detail error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Product add endpoint
app.post('/productadd', async (req, res) => {
  try {
    const {
      PROD_SUB_CAT_ID,
      PROD_NAME,
      PROD_CODE,
      PROD_DESC,
      PROD_MRP,
      PROD_SP,
      PROD_REORDER_LEVEL,
      PROD_QOH,
      PROD_HSN_CODE,
      PROD_CGST,
      PROD_IGST,
      PROD_SGST,
      PROD_MFG_DATE,
      PROD_EXPIRY_DATE,
      PROD_MFG_BY,
      PROD_IMAGE_1,
      PROD_IMAGE_2,
      PROD_IMAGE_3,
      PROD_CAT_ID
    } = req.body;

    const [result] = await db.promise().query(
      `INSERT INTO product (
        PROD_SUB_CAT_ID, PROD_NAME, PROD_CODE, PROD_DESC, PROD_MRP, PROD_SP,
        PROD_REORDER_LEVEL, PROD_QOH, PROD_HSN_CODE, PROD_CGST, PROD_IGST,
        PROD_SGST, PROD_MFG_DATE, PROD_EXPIRY_DATE, PROD_MFG_BY, PROD_IMAGE_1,
        PROD_IMAGE_2, PROD_IMAGE_3, CREATED_BY, UPDATED_BY, CREATED_DATE,
        UPDATED_DATE, PROD_CAT_ID
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), ?)`,
      [
        PROD_SUB_CAT_ID, PROD_NAME, PROD_CODE, PROD_DESC, PROD_MRP, PROD_SP,
        PROD_REORDER_LEVEL, PROD_QOH, PROD_HSN_CODE, PROD_CGST, PROD_IGST,
        PROD_SGST, PROD_MFG_DATE, PROD_EXPIRY_DATE, PROD_MFG_BY, PROD_IMAGE_1,
        PROD_IMAGE_2, PROD_IMAGE_3, 'SYSTEM', 'SYSTEM', PROD_CAT_ID
      ]
    );

    res.status(201).json({ message: 'Product added successfully', productId: result.insertId });
  } catch (error) {
    console.error('Product add error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Product edit endpoint
app.put('/productedit/:id', async (req, res) => {
  try {
    const {
      PROD_SUB_CAT_ID,
      PROD_NAME,
      PROD_CODE,
      PROD_DESC,
      PROD_MRP,
      PROD_SP,
      PROD_REORDER_LEVEL,
      PROD_QOH,
      PROD_HSN_CODE,
      PROD_CGST,
      PROD_IGST,
      PROD_SGST,
      PROD_MFG_DATE,
      PROD_EXPIRY_DATE,
      PROD_MFG_BY,
      PROD_IMAGE_1,
      PROD_IMAGE_2,
      PROD_IMAGE_3,
      PROD_CAT_ID
    } = req.body;

    await db.promise().query(
      `UPDATE product SET
        PROD_SUB_CAT_ID = ?, PROD_NAME = ?, PROD_CODE = ?, PROD_DESC = ?,
        PROD_MRP = ?, PROD_SP = ?, PROD_REORDER_LEVEL = ?, PROD_QOH = ?,
        PROD_HSN_CODE = ?, PROD_CGST = ?, PROD_IGST = ?, PROD_SGST = ?,
        PROD_MFG_DATE = ?, PROD_EXPIRY_DATE = ?, PROD_MFG_BY = ?, PROD_IMAGE_1 = ?,
        PROD_IMAGE_2 = ?, PROD_IMAGE_3 = ?, UPDATED_BY = ?, UPDATED_DATE = NOW(),
        PROD_CAT_ID = ?
      WHERE PROD_ID = ?`,
      [
        PROD_SUB_CAT_ID, PROD_NAME, PROD_CODE, PROD_DESC, PROD_MRP, PROD_SP,
        PROD_REORDER_LEVEL, PROD_QOH, PROD_HSN_CODE, PROD_CGST, PROD_IGST,
        PROD_SGST, PROD_MFG_DATE, PROD_EXPIRY_DATE, PROD_MFG_BY, PROD_IMAGE_1,
        PROD_IMAGE_2, PROD_IMAGE_3, 'SYSTEM', PROD_CAT_ID, req.params.id
      ]
    );

    res.json({ message: 'Product updated successfully' });
  } catch (error) {
    console.error('Product edit error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Add to cart endpoint
app.post('/addtocart', async (req, res) => {
  try {
    const { userId, productId, quantity } = req.body;

    // Check if product exists in cart
    const [existingItems] = await db.promise().query(
      'SELECT * FROM cust_order_details WHERE COD_CO_ID = ? AND PROD_ID = ?',
      [userId, productId]
    );

    if (existingItems.length > 0) {
      // Update quantity
      await db.promise().query(
        'UPDATE cust_order_details SET COD_QTY = COD_QTY + ? WHERE COD_CO_ID = ? AND PROD_ID = ?',
        [quantity, userId, productId]
      );
    } else {
      // Add new item
      const [product] = await db.promise().query(
        'SELECT * FROM product WHERE PROD_ID = ?',
        [productId]
      );

      if (product.length === 0) {
        return res.status(404).json({ message: 'Product not found' });
      }

      await db.promise().query(
        `INSERT INTO cust_order_details (
          COD_CO_ID, COD_QTY, PROD_NAME, PROD_BARCODE, PROD_DESC,
          PROD_MRP, PROD_SP, PROD_CGST, PROD_IGST, PROD_SGST,
          PROD_IMAGE_1, PROD_IMAGE_2, PROD_IMAGE_3, PROD_CODE, PROD_ID
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          userId, quantity, product[0].PROD_NAME, product[0].PROD_CODE,
          product[0].PROD_DESC, product[0].PROD_MRP, product[0].PROD_SP,
          product[0].PROD_CGST, product[0].PROD_IGST, product[0].PROD_SGST,
          product[0].PROD_IMAGE_1, product[0].PROD_IMAGE_2, product[0].PROD_IMAGE_3,
          product[0].PROD_CODE, productId
        ]
      );
    }

    res.json({ message: 'Item added to cart successfully' });
  } catch (error) {
    console.error('Add to cart error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Get cart endpoint
app.get('/getcart/:userId', async (req, res) => {
  try {
    const [cartItems] = await db.promise().query(
      'SELECT * FROM cust_order_details WHERE COD_CO_ID = ?',
      [req.params.userId]
    );
    res.json(cartItems);
  } catch (error) {
    console.error('Get cart error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Retailer list endpoint
app.get('/retailerlist', async (req, res) => {
  try {
    const [retailers] = await db.promise().query(
      'SELECT * FROM retailer_info WHERE RET_DEL_STATUS = "active"'
    );
    res.json(retailers);
  } catch (error) {
    console.error('Retailer list error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Retailer details endpoint
app.get('/retailerdetails/:id', async (req, res) => {
  try {
    const [retailers] = await db.promise().query(
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
});

// Order list endpoint
app.get('/orderlist/:userId', async (req, res) => {
  try {
    const [orders] = await db.promise().query(
      'SELECT * FROM cust_order WHERE CO_CUST_CODE = ?',
      [req.params.userId]
    );
    res.json(orders);
  } catch (error) {
    console.error('Order list error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
}); 