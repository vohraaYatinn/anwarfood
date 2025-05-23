const express = require('express');
const router = express.Router();
const { addToCart, fetchCart, placeOrder } = require('../controllers/cart.controller');
const authMiddleware = require('../middleware/auth.middleware');

router.post('/add', authMiddleware, addToCart);
router.get('/fetch', authMiddleware, fetchCart);
router.post('/place-order', authMiddleware, placeOrder);

module.exports = router; 