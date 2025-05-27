const express = require('express');
const router = express.Router();
const { 
  signup, 
  login, 
  verifyOtp, 
  resetPassword, 
  verifyOtpPassword, 
  changePassword 
} = require('../controllers/auth.controller');

router.post('/signup', signup);
router.post('/login', login);
router.post('/verify-otp', verifyOtp);
router.post('/reset-password', resetPassword);
router.post('/verify-otp-password', verifyOtpPassword);
router.post('/change-password', changePassword);

module.exports = router; 