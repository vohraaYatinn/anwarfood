const express = require('express');
const router = express.Router();
const { getOrderList } = require('../controllers/orderController');
const auth = require('../middleware/auth');

router.get('/orderlist/:userId', auth, getOrderList);

module.exports = router; 