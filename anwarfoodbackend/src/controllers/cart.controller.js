const { pool: db } = require('../config/database');

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

    // Fetch cart items with complete product and unit details
    const [cartItems] = await db.promise().query(`
      SELECT 
        c.CART_ID,
        c.USER_ID,
        c.PROD_ID,
        c.UNIT_ID,
        c.QUANTITY,
        c.CREATED_DATE,
        p.PROD_SUB_CAT_ID,
        p.PROD_NAME,
        p.PROD_CODE,
        p.PROD_DESC,
        p.PROD_MRP,
        p.PROD_SP,
        p.PROD_REORDER_LEVEL,
        p.PROD_QOH,
        p.PROD_HSN_CODE,
        p.PROD_CGST,
        p.PROD_IGST,
        p.PROD_SGST,
        p.PROD_MFG_DATE,
        p.PROD_EXPIRY_DATE,
        p.PROD_MFG_BY,
        p.PROD_IMAGE_1,
        p.PROD_IMAGE_2,
        p.PROD_IMAGE_3,
        p.PROD_CAT_ID,
        pu.PU_PROD_UNIT,
        pu.PU_PROD_UNIT_VALUE,
        pu.PU_PROD_RATE,
        pu.PU_STATUS
      FROM cart c
      JOIN product p ON c.PROD_ID = p.PROD_ID
      JOIN product_unit pu ON c.UNIT_ID = pu.PU_ID
      WHERE c.USER_ID = ? AND p.DEL_STATUS != 'Y'
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

    // Calculate totals using PU_PROD_RATE
    const cartTotal = cartItems.reduce((total, item) => {
      return total + (item.PU_PROD_RATE * item.QUANTITY);
    }, 0);

    // Format response with nested product and unit details
    const formattedCartItems = cartItems.map(item => ({
      cartId: item.CART_ID,
      userId: item.USER_ID,
      quantity: item.QUANTITY,
      createdDate: item.CREATED_DATE,
      product: {
        id: item.PROD_ID,
        subCategoryId: item.PROD_SUB_CAT_ID,
        categoryId: item.PROD_CAT_ID,
        name: item.PROD_NAME,
        code: item.PROD_CODE,
        description: item.PROD_DESC,
        mrp: item.PROD_MRP,
        sellingPrice: item.PROD_SP,
        reorderLevel: item.PROD_REORDER_LEVEL,
        quantityOnHand: item.PROD_QOH,
        hsnCode: item.PROD_HSN_CODE,
        cgst: item.PROD_CGST,
        igst: item.PROD_IGST,
        sgst: item.PROD_SGST,
        manufacturingDate: item.PROD_MFG_DATE,
        expiryDate: item.PROD_EXPIRY_DATE,
        manufacturedBy: item.PROD_MFG_BY,
        images: {
          image1: item.PROD_IMAGE_1,
          image2: item.PROD_IMAGE_2,
          image3: item.PROD_IMAGE_3
        }
      },
      unit: {
        id: item.UNIT_ID,
        name: item.PU_PROD_UNIT,
        value: item.PU_PROD_UNIT_VALUE,
        rate: item.PU_PROD_RATE,
        status: item.PU_STATUS
      },
      itemTotal: item.PU_PROD_RATE * item.QUANTITY
    }));

    res.json({
      success: true,
      data: {
        items: formattedCartItems,
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

const increaseQuantity = async (req, res) => {
  try {
    const { cartId } = req.body;
    const userId = req.user.userId;

    // Get cart item with product unit details
    const [cartItems] = await db.promise().query(`
      SELECT c.*, pu.PU_PROD_UNIT_VALUE, pu.PU_PROD_RATE
      FROM cart c
      JOIN product_unit pu ON c.UNIT_ID = pu.PU_ID
      WHERE c.CART_ID = ? AND c.USER_ID = ?
    `, [cartId, userId]);

    if (cartItems.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Cart item not found or does not belong to user'
      });
    }

    const cartItem = cartItems[0];
    const unitValue = cartItem.PU_PROD_UNIT_VALUE;

    // Increase quantity by unit value
    await db.promise().query(
      'UPDATE cart SET QUANTITY = QUANTITY + ? WHERE CART_ID = ? AND USER_ID = ?',
      [unitValue, cartId, userId]
    );

    // Get updated cart item details
    const [updatedItem] = await db.promise().query(`
      SELECT c.*, p.PROD_NAME, pu.PU_PROD_RATE, pu.PU_PROD_UNIT_VALUE
      FROM cart c
      JOIN product p ON c.PROD_ID = p.PROD_ID
      JOIN product_unit pu ON c.UNIT_ID = pu.PU_ID
      WHERE c.CART_ID = ? AND c.USER_ID = ?
    `, [cartId, userId]);

    res.json({
      success: true,
      message: 'Quantity increased successfully',
      data: {
        cartId: updatedItem[0].CART_ID,
        quantity: updatedItem[0].QUANTITY,
        itemTotal: updatedItem[0].PU_PROD_RATE * updatedItem[0].QUANTITY
      }
    });
  } catch (error) {
    console.error('Increase quantity error:', error);
    res.status(500).json({
      success: false,
      message: 'Error increasing quantity',
      error: error.message
    });
  }
};

const decreaseQuantity = async (req, res) => {
  try {
    const { cartId } = req.body;
    const userId = req.user.userId;

    // Get cart item with product unit details
    const [cartItems] = await db.promise().query(`
      SELECT c.*, pu.PU_PROD_UNIT_VALUE, pu.PU_PROD_RATE
      FROM cart c
      JOIN product_unit pu ON c.UNIT_ID = pu.PU_ID
      WHERE c.CART_ID = ? AND c.USER_ID = ?
    `, [cartId, userId]);

    if (cartItems.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Cart item not found or does not belong to user'
      });
    }

    const cartItem = cartItems[0];
    const unitValue = cartItem.PU_PROD_UNIT_VALUE;
    const currentQuantity = cartItem.QUANTITY;

    // If quantity after decrease would be less than or equal to unit value, remove item
    if (currentQuantity <= unitValue) {
      await db.promise().query(
        'DELETE FROM cart WHERE CART_ID = ? AND USER_ID = ?',
        [cartId, userId]
      );

      return res.json({
        success: true,
        message: 'Item removed from cart',
        data: {
          cartId: cartId,
          quantity: 0,
          itemTotal: 0,
          removed: true
        }
      });
    }

    // Decrease quantity by unit value
    await db.promise().query(
      'UPDATE cart SET QUANTITY = QUANTITY - ? WHERE CART_ID = ? AND USER_ID = ?',
      [unitValue, cartId, userId]
    );

    // Get updated cart item details
    const [updatedItem] = await db.promise().query(`
      SELECT c.*, p.PROD_NAME, pu.PU_PROD_RATE, pu.PU_PROD_UNIT_VALUE
      FROM cart c
      JOIN product p ON c.PROD_ID = p.PROD_ID
      JOIN product_unit pu ON c.UNIT_ID = pu.PU_ID
      WHERE c.CART_ID = ? AND c.USER_ID = ?
    `, [cartId, userId]);

    res.json({
      success: true,
      message: 'Quantity decreased successfully',
      data: {
        cartId: updatedItem[0].CART_ID,
        quantity: updatedItem[0].QUANTITY,
        itemTotal: updatedItem[0].PU_PROD_RATE * updatedItem[0].QUANTITY,
        removed: false
      }
    });
  } catch (error) {
    console.error('Decrease quantity error:', error);
    res.status(500).json({
      success: false,
      message: 'Error decreasing quantity',
      error: error.message
    });
  }
};

const getCartItemCount = async (req, res) => {
  try {
    const userId = req.user.userId;

    // Get total items count and sum of quantities
    const [result] = await db.promise().query(`
      SELECT 
        COUNT(CART_ID) as total_items,
        COALESCE(SUM(QUANTITY), 0) as total_quantity
      FROM cart 
      WHERE USER_ID = ?
    `, [userId]);

    res.json({
      success: true,
      data: {
        totalItems: result[0].total_items,
        totalQuantity: result[0].total_quantity
      }
    });
  } catch (error) {
    console.error('Get cart count error:', error);
    res.status(500).json({
      success: false,
      message: 'Error getting cart count',
      error: error.message
    });
  }
};

module.exports = {
  addToCart,
  fetchCart,
  placeOrder,
  increaseQuantity,
  decreaseQuantity,
  getCartItemCount
}; 