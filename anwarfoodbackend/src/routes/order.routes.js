const express = require('express');
const router = express.Router();
const { getOrderList, getOrderDetails } = require('../controllers/order.controller');
const authMiddleware = require('../middleware/auth.middleware');

router.get('/list', authMiddleware, getOrderList);
router.get('/details/:orderId', authMiddleware, getOrderDetails);

module.exports = router; 