const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const {
  getRetailerList,
  getRetailerInfo,
  getRetailerByUserMobile,
  updateRetailerProfile,
  getRetailerByIdAdmin,
  searchRetailers
} = require('../controllers/retailer.controller');

// Get list of retailers
router.get('/list', authMiddleware, getRetailerList);

// Get retailer info
router.get('/info/:retailerId', authMiddleware, getRetailerInfo);

// Get retailer info by logged-in user's mobile number
router.get('/my-retailer', authMiddleware, getRetailerByUserMobile);

// Update retailer profile for logged-in user
router.put('/my-retailer', authMiddleware, updateRetailerProfile);

// Get retailer info by ID (admin)
router.get('/admin/retailer-details/:retailerId', authMiddleware, getRetailerByIdAdmin);

// Search retailers by code, shop name, or mobile number
router.get('/search', authMiddleware, searchRetailers);

module.exports = router;
