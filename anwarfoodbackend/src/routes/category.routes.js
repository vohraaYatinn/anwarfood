const express = require('express');
const router = express.Router();
const { getCategoryList } = require('../controllers/category.controller');
const authMiddleware = require('../middleware/auth.middleware');

router.get('/list', authMiddleware, getCategoryList);

module.exports = router; 