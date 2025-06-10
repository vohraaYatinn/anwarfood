const express = require('express');
const router = express.Router();
const employeeMiddleware = require('../middleware/employee.middleware');
const { orderPaymentUpload } = require('../middleware/upload.middleware');
const {
  fetchOrders,
  searchOrders,
  getOrderDetails,
  updateOrderStatus,
  placeOrderForCustomer,
  getRetailerList,
  searchRetailers
} = require('../controllers/employee.controller');

// Apply employee middleware to all routes
router.use(employeeMiddleware);

// Order Management Routes
router.get('/orders', fetchOrders);
router.get('/orders/search', searchOrders);
router.get('/orders/:orderId', getOrderDetails);
router.put('/orders/:orderId/status', orderPaymentUpload, updateOrderStatus);
router.post('/place-order', placeOrderForCustomer);

// Retailer Management Routes
router.get('/retailers', getRetailerList);
router.get('/retailers/search', searchRetailers);

module.exports = router; 