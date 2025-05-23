const db = require('../config/database');

const getProductList = async (req, res) => {
  try {
    const [products] = await db.promise().query(`
      SELECT p.*, c.CATEGORY_NAME, sc.SUB_CATEGORY_NAME 
      FROM product p
      LEFT JOIN category c ON p.PROD_CAT_ID = c.CATEGORY_ID
      LEFT JOIN sub_category sc ON p.PROD_SUB_CAT_ID = sc.SUB_CATEGORY_ID
      WHERE p.DEL_STATUS IS NULL OR p.DEL_STATUS != 'Y'
    `);

    res.json({
      success: true,
      data: products
    });
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching products',
      error: error.message
    });
  }
};

const getProductDetails = async (req, res) => {
  try {
    const { id } = req.params;

    const [products] = await db.promise().query(`
      SELECT p.*, c.CATEGORY_NAME, sc.SUB_CATEGORY_NAME,
      GROUP_CONCAT(pb.PRDB_BARCODE) as barcodes
      FROM product p
      LEFT JOIN category c ON p.PROD_CAT_ID = c.CATEGORY_ID
      LEFT JOIN sub_category sc ON p.PROD_SUB_CAT_ID = sc.SUB_CATEGORY_ID
      LEFT JOIN product_barcodes pb ON p.PROD_ID = pb.PRDB_PROD_ID
      WHERE p.PROD_ID = ? AND (p.DEL_STATUS IS NULL OR p.DEL_STATUS != 'Y')
      GROUP BY p.PROD_ID
    `, [id]);

    if (products.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    // Get product units
    const [units] = await db.promise().query(
      'SELECT * FROM product_unit WHERE PU_PROD_ID = ?',
      [id]
    );

    const product = {
      ...products[0],
      units: units
    };

    res.json({
      success: true,
      data: product
    });
  } catch (error) {
    console.error('Error fetching product details:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching product details',
      error: error.message
    });
  }
};

const getProductsUnderCategory = async (req, res) => {
  try {
    const { categoryId } = req.params;

    // First verify if category exists
    const [categories] = await db.promise().query(
      'SELECT * FROM category WHERE CATEGORY_ID = ? AND DEL_STATUS != "Y"',
      [categoryId]
    );

    if (categories.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }

    // Get products under this category
    const [products] = await db.promise().query(`
      SELECT p.*, c.CATEGORY_NAME, sc.SUB_CATEGORY_NAME,
      GROUP_CONCAT(DISTINCT pu.PU_ID, ':', pu.PU_PROD_UNIT, ':', pu.PU_PROD_UNIT_VALUE, ':', pu.PU_PROD_RATE) as units
      FROM product p
      LEFT JOIN category c ON p.PROD_CAT_ID = c.CATEGORY_ID
      LEFT JOIN sub_category sc ON p.PROD_SUB_CAT_ID = sc.SUB_CATEGORY_ID
      LEFT JOIN product_unit pu ON p.PROD_ID = pu.PU_PROD_ID
      WHERE p.PROD_CAT_ID = ? AND (p.DEL_STATUS IS NULL OR p.DEL_STATUS != 'Y')
      GROUP BY p.PROD_ID
    `, [categoryId]);

    // Format the units data
    const formattedProducts = products.map(product => ({
      ...product,
      units: product.units
        ? product.units.split(',').map(unitStr => {
            const [unitId, unitName, unitValue, unitRate] = unitStr.split(':');
            return { 
              id: unitId, 
              name: unitName, 
              value: unitValue, 
              rate: unitRate 
            };
          })
        : []
    }));

    res.json({
      success: true,
      data: formattedProducts
    });
  } catch (error) {
    console.error('Error fetching products under category:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching products under category',
      error: error.message
    });
  }
};

module.exports = {
  getProductList,
  getProductDetails,
  getProductsUnderCategory
}; 