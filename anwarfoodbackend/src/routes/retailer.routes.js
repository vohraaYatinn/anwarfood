const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const {
  getRetailerList,
  getRetailerInfo,
  getRetailerByUserMobile
} = require('../controllers/retailer.controller');

// Get list of retailers
router.get('/list', authMiddleware, getRetailerList);

// Get retailer info
router.get('/info/:retailerId', authMiddleware, getRetailerInfo);

// Get retailer info by logged-in user's mobile number
router.get('/my-retailer', authMiddleware, getRetailerByUserMobile);

module.exports = router; 