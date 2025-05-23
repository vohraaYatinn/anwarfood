const express = require('express');
const router = express.Router();
const { getProductList, getProductDetail, addProduct, editProduct } = require('../controllers/productController');
const auth = require('../middleware/auth');

router.get('/productlist', getProductList);
router.get('/productdetail/:id', getProductDetail);
router.post('/productadd', auth, addProduct);
router.put('/productedit/:id', auth, editProduct);

module.exports = router; 