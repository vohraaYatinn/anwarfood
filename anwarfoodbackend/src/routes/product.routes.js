const express = require('express');
const router = express.Router();
const { getProductList, getProductDetails, getProductsUnderCategory, getProductUnits, searchProducts } = require('../controllers/product.controller');
const authMiddleware = require('../middleware/auth.middleware');

router.get('/list', authMiddleware, getProductList);
router.get('/details/:id', authMiddleware, getProductDetails);
router.get('/category/:categoryId', authMiddleware, getProductsUnderCategory);
router.get('/units/:productId', authMiddleware, getProductUnits);
router.get('/search', authMiddleware, searchProducts);

module.exports = router; 