const db = require('../config/database');

const addToCart = async (req, res) => {
  try {
    const { userId, productId, quantity } = req.body;

    // Check if product exists in cart
    const [existingItems] = await db.query(
      'SELECT * FROM cust_order_details WHERE COD_CO_ID = ? AND PROD_ID = ?',
      [userId, productId]
    );

    if (existingItems.length > 0) {
      // Update quantity
      await db.query(
        'UPDATE cust_order_details SET COD_QTY = COD_QTY + ? WHERE COD_CO_ID = ? AND PROD_ID = ?',
        [quantity, userId, productId]
      );
    } else {
      // Add new item
      const [product] = await db.query(
        'SELECT * FROM product WHERE PROD_ID = ?',
        [productId]
      );

      if (product.length === 0) {
        return res.status(404).json({ message: 'Product not found' });
      }

      await db.query(
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
};

const getCart = async (req, res) => {
  try {
    const [cartItems] = await db.query(
      'SELECT * FROM cust_order_details WHERE COD_CO_ID = ?',
      [req.params.userId]
    );
    res.json(cartItems);
  } catch (error) {
    console.error('Get cart error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

module.exports = {
  addToCart,
  getCart
}; 