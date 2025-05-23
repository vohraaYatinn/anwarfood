const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const {
  getAddressList,
  addAddress,
  editAddress
} = require('../controllers/address.controller');

// Get list of customer addresses
router.get('/list', authMiddleware, getAddressList);

// Add new customer address
router.post('/add', authMiddleware, addAddress);

// Edit customer address
router.put('/edit/:addressId', authMiddleware, editAddress);

module.exports = router; 