const express = require('express');
const router = express.Router();
const employeeMiddleware = require('../middleware/employee.middleware');
const {
  fetchOrders,
  searchOrders,
  getOrderDetails,
  updateOrderStatus
} = require('../controllers/employee.controller');

// Apply employee middleware to all routes
router.use(employeeMiddleware);

// Order Management Routes
router.get('/orders', fetchOrders);
router.get('/orders/search', searchOrders);
router.get('/orders/:orderId', getOrderDetails);
router.put('/orders/:orderId/status', updateOrderStatus);

module.exports = router; 