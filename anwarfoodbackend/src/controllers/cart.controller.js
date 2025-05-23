const db = require('../config/database');

const addToCart = async (req, res) => {
  try {
    const { productId, quantity, unitId } = req.body;
    const userId = req.user.userId;

    // First check if product exists and get its details
    const [products] = await db.promise().query(
      'SELECT * FROM product WHERE PROD_ID = ? AND (DEL_STATUS IS NULL OR DEL_STATUS != "Y")',
      [productId]
    );

    if (products.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    // Check if product unit exists
    const [units] = await db.promise().query(
      'SELECT * FROM product_unit WHERE PU_ID = ? AND PU_PROD_ID = ?',
      [unitId, productId]
    );

    if (units.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Product unit not found'
      });
    }

    // Check if item already exists in cart
    const [existingItems] = await db.promise().query(
      'SELECT * FROM cart WHERE USER_ID = ? AND PROD_ID = ? AND UNIT_ID = ?',
      [userId, productId, unitId]
    );

    if (existingItems.length > 0) {
      // Update quantity if item exists
      await db.promise().query(
        'UPDATE cart SET QUANTITY = QUANTITY + ? WHERE USER_ID = ? AND PROD_ID = ? AND UNIT_ID = ?',
        [quantity, userId, productId, unitId]
      );
    } else {
      // Insert new cart item
      await db.promise().query(
        'INSERT INTO cart (USER_ID, PROD_ID, UNIT_ID, QUANTITY, CREATED_DATE) VALUES (?, ?, ?, ?, NOW())',
        [userId, productId, unitId, quantity]
      );
    }

    res.json({
      success: true,
      message: 'Item added to cart successfully'
    });
  } catch (error) {
    console.error('Add to cart error:', error);
    res.status(500).json({
      success: false,
      message: 'Error adding item to cart',
      error: error.message
    });
  }
};

const fetchCart = async (req, res) => {
  try {
    const userId = req.user.userId;

    // Fetch cart items
    const [cartItems] = await db.promise().query(`
      SELECT c.*, p.PROD_NAME, p.PROD_IMAGE_1, p.PROD_MRP, p.PROD_SP,
             pu.PU_PROD_UNIT, pu.PU_PROD_UNIT_VALUE, pu.PU_PROD_RATE
      FROM cart c
      JOIN product p ON c.PROD_ID = p.PROD_ID
      JOIN product_unit pu ON c.UNIT_ID = pu.PU_ID
      WHERE c.USER_ID = ?
    `, [userId]);

    // Fetch default address
    const [defaultAddress] = await db.promise().query(`
      SELECT * FROM customer_address 
      WHERE USER_ID = ? AND IS_DEFAULT = 1 AND DEL_STATUS != 'Y'
      LIMIT 1
    `, [userId]);

    // If no default address, get the first address
    let selectedAddress = null;
    if (defaultAddress.length > 0) {
      selectedAddress = defaultAddress[0];
    } else {
      const [firstAddress] = await db.promise().query(`
        SELECT * FROM customer_address 
        WHERE USER_ID = ? AND DEL_STATUS != 'Y'
        ORDER BY CREATED_DATE DESC
        LIMIT 1
      `, [userId]);
      
      if (firstAddress.length > 0) {
        selectedAddress = firstAddress[0];
      }
    }

    // Calculate totals
    const cartTotal = cartItems.reduce((total, item) => {
      return total + (item.PU_PROD_RATE * item.QUANTITY);
    }, 0);

    res.json({
      success: true,
      data: {
        items: cartItems,
        total: cartTotal,
        selectedAddress: selectedAddress
      }
    });
  } catch (error) {
    console.error('Fetch cart error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching cart',
      error: error.message
    });
  }
};

// Place Order function
const placeOrder = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { addressId, paymentMethod, notes } = req.body;

    // Start transaction
    await db.promise().query('START TRANSACTION');

    try {
      // Get cart items
      const [cartItems] = await db.promise().query(`
        SELECT c.*, p.PROD_NAME, p.PROD_MRP, p.PROD_SP,
               pu.PU_PROD_UNIT, pu.PU_PROD_UNIT_VALUE, pu.PU_PROD_RATE
        FROM cart c
        JOIN product p ON c.PROD_ID = p.PROD_ID
        JOIN product_unit pu ON c.UNIT_ID = pu.PU_ID
        WHERE c.USER_ID = ?
      `, [userId]);

      if (cartItems.length === 0) {
        await db.promise().query('ROLLBACK');
        return res.status(400).json({
          success: false,
          message: 'Cart is empty'
        });
      }

      // Get address details
      let orderAddress = null;
      if (addressId) {
        const [address] = await db.promise().query(
          'SELECT * FROM customer_address WHERE ADDRESS_ID = ? AND USER_ID = ?',
          [addressId, userId]
        );
        
        if (address.length === 0) {
          await db.promise().query('ROLLBACK');
          return res.status(404).json({
            success: false,
            message: 'Address not found'
          });
        }
        orderAddress = address[0];
      } else {
        // Use default address
        const [defaultAddr] = await db.promise().query(
          'SELECT * FROM customer_address WHERE USER_ID = ? AND IS_DEFAULT = 1 AND DEL_STATUS != "Y" LIMIT 1',
          [userId]
        );
        
        if (defaultAddr.length === 0) {
          await db.promise().query('ROLLBACK');
          return res.status(400).json({
            success: false,
            message: 'No default address found. Please select an address.'
          });
        }
        orderAddress = defaultAddr[0];
      }

      // Calculate order total
      const orderTotal = cartItems.reduce((total, item) => {
        return total + (item.PU_PROD_RATE * item.QUANTITY);
      }, 0);

      // Generate order number
      const orderNumber = 'ORD' + Date.now();

      // Create order
      const [orderResult] = await db.promise().query(`
        INSERT INTO orders (
          ORDER_NUMBER, USER_ID, ORDER_TOTAL, ORDER_STATUS, 
          DELIVERY_ADDRESS, DELIVERY_CITY, DELIVERY_STATE, 
          DELIVERY_COUNTRY, DELIVERY_PINCODE, DELIVERY_LANDMARK,
          PAYMENT_METHOD, ORDER_NOTES, CREATED_DATE
        ) VALUES (?, ?, ?, 'pending', ?, ?, ?, ?, ?, ?, ?, ?, NOW())
      `, [
        orderNumber, userId, orderTotal, 
        orderAddress.ADDRESS, orderAddress.CITY, orderAddress.STATE,
        orderAddress.COUNTRY, orderAddress.PINCODE, orderAddress.LANDMARK,
        paymentMethod || 'cod', notes || ''
      ]);

      const orderId = orderResult.insertId;

      // Create order items
      for (const item of cartItems) {
        await db.promise().query(`
          INSERT INTO order_items (
            ORDER_ID, PROD_ID, UNIT_ID, QUANTITY, 
            UNIT_PRICE, TOTAL_PRICE, CREATED_DATE
          ) VALUES (?, ?, ?, ?, ?, ?, NOW())
        `, [
          orderId, item.PROD_ID, item.UNIT_ID, item.QUANTITY,
          item.PU_PROD_RATE, (item.PU_PROD_RATE * item.QUANTITY)
        ]);
      }

      // Clear cart
      await db.promise().query('DELETE FROM cart WHERE USER_ID = ?', [userId]);

      // Commit transaction
      await db.promise().query('COMMIT');

      res.status(201).json({
        success: true,
        message: 'Order placed successfully',
        data: {
          orderId: orderId,
          orderNumber: orderNumber,
          orderTotal: orderTotal,
          deliveryAddress: {
            address: orderAddress.ADDRESS,
            city: orderAddress.CITY,
            state: orderAddress.STATE,
            country: orderAddress.COUNTRY,
            pincode: orderAddress.PINCODE,
            landmark: orderAddress.LANDMARK
          }
        }
      });

    } catch (error) {
      await db.promise().query('ROLLBACK');
      throw error;
    }

  } catch (error) {
    console.error('Place order error:', error);
    res.status(500).json({
      success: false,
      message: 'Error placing order',
      error: error.message
    });
  }
};

module.exports = {
  addToCart,
  fetchCart,
  placeOrder
}; 