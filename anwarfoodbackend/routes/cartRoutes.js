const express = require('express');
const router = express.Router();
const { addToCart, getCart } = require('../controllers/cartController');
const auth = require('../middleware/auth');

router.post('/addtocart', auth, addToCart);
router.get('/getcart/:userId', auth, getCart);

module.exports = router; 