const express = require('express');
const router = express.Router();
const { getProductList, getProductDetails, getProductsUnderCategory, getProductsUnderSubCategory, getProductUnits, searchProducts, getProductIdByBarcode } = require('../controllers/product.controller');
const { productImagesUpload } = require('../middleware/upload.middleware');
const authMiddleware = require('../middleware/auth.middleware');
<<<<<<< HEAD
const { base_url } = require('../../environment');
=======
const { base_url } = require('../environment');
>>>>>>> 883a26ad3e0c7f1e85864d8b4a8a85bbdb098783

router.get('/list', authMiddleware, getProductList);
router.get('/details/:id', authMiddleware, getProductDetails);
router.get('/category/:categoryId', authMiddleware, getProductsUnderCategory);
router.get('/subcategory/:subCategoryId', authMiddleware, getProductsUnderSubCategory);
router.get('/units/:productId', authMiddleware, getProductUnits);
router.get('/search', authMiddleware, searchProducts);
router.post('/get-by-barcode', authMiddleware, getProductIdByBarcode);

// Example route for uploading product images
router.post('/upload-images', authMiddleware, productImagesUpload, (req, res) => {
  try {
    if (!req.uploadedFiles || req.uploadedFiles.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No product images uploaded'
      });
    }

    const uploadedImages = req.uploadedFiles.map(file => ({
      filename: file.filename,
<<<<<<< HEAD
      path: `${base_url}/uploads/products/${file.filename}`,
      full_path: `${base_url}/uploads/products/${file.filename}`,
=======
      path: file.path,
      url: `${base_url}/uploads/products/${file.filename}`,
>>>>>>> 883a26ad3e0c7f1e85864d8b4a8a85bbdb098783
      originalname: file.originalname,
      size: file.size
    }));

    res.json({
      success: true,
      message: `${req.uploadedFiles.length} product image(s) uploaded successfully`,
      data: {
        images: uploadedImages,
        count: req.uploadedFiles.length
      }
    });
  } catch (error) {
    console.error('Product images upload error:', error);
    res.status(500).json({
      success: false,
      message: 'Error uploading product images',
      error: error.message
    });
  }
});

module.exports = router; 