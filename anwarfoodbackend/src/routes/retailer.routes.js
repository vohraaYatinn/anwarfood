const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const {
  getRetailerList,
  getRetailerInfo
} = require('../controllers/retailer.controller');

// Get list of retailers
router.get('/list', authMiddleware, getRetailerList);

// Get retailer info
router.get('/info/:retailerId', authMiddleware, getRetailerInfo);

module.exports = router; 