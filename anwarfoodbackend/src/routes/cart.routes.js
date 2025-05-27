const express = require('express');
const router = express.Router();
const { 
  addToCart, 
  fetchCart, 
  placeOrder, 
  increaseQuantity, 
  decreaseQuantity 
} = require('../controllers/cart.controller');
const authMiddleware = require('../middleware/auth.middleware');

router.post('/add', authMiddleware, addToCart);
router.get('/fetch', authMiddleware, fetchCart);
router.post('/place-order', authMiddleware, placeOrder);
router.post('/increase-quantity', authMiddleware, increaseQuantity);
router.post('/decrease-quantity', authMiddleware, decreaseQuantity);

module.exports = router; 