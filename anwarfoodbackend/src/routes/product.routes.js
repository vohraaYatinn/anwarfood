const express = require('express');
const router = express.Router();
const { getProductList, getProductDetails, getProductsUnderCategory, getProductUnits } = require('../controllers/product.controller');
const authMiddleware = require('../middleware/auth.middleware');

router.get('/list', authMiddleware, getProductList);
router.get('/details/:id', authMiddleware, getProductDetails);
router.get('/category/:categoryId', authMiddleware, getProductsUnderCategory);
router.get('/units/:productId', authMiddleware, getProductUnits);

module.exports = router; 