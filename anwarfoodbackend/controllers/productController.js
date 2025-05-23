const db = require('../config/database');

const getProductList = async (req, res) => {
  try {
    const [products] = await db.query(
      'SELECT * FROM product WHERE DEL_STATUS IS NULL OR DEL_STATUS != "Y"'
    );
    res.json(products);
  } catch (error) {
    console.error('Product list error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

const getProductDetail = async (req, res) => {
  try {
    const [products] = await db.query(
      'SELECT * FROM product WHERE PROD_ID = ?',
      [req.params.id]
    );

    if (products.length === 0) {
      return res.status(404).json({ message: 'Product not found' });
    }

    res.json(products[0]);
  } catch (error) {
    console.error('Product detail error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

const addProduct = async (req, res) => {
  try {
    const {
      PROD_SUB_CAT_ID,
      PROD_NAME,
      PROD_CODE,
      PROD_DESC,
      PROD_MRP,
      PROD_SP,
      PROD_REORDER_LEVEL,
      PROD_QOH,
      PROD_HSN_CODE,
      PROD_CGST,
      PROD_IGST,
      PROD_SGST,
      PROD_MFG_DATE,
      PROD_EXPIRY_DATE,
      PROD_MFG_BY,
      PROD_IMAGE_1,
      PROD_IMAGE_2,
      PROD_IMAGE_3,
      PROD_CAT_ID
    } = req.body;

    const [result] = await db.query(
      `INSERT INTO product (
        PROD_SUB_CAT_ID, PROD_NAME, PROD_CODE, PROD_DESC, PROD_MRP, PROD_SP,
        PROD_REORDER_LEVEL, PROD_QOH, PROD_HSN_CODE, PROD_CGST, PROD_IGST,
        PROD_SGST, PROD_MFG_DATE, PROD_EXPIRY_DATE, PROD_MFG_BY, PROD_IMAGE_1,
        PROD_IMAGE_2, PROD_IMAGE_3, CREATED_BY, UPDATED_BY, CREATED_DATE,
        UPDATED_DATE, PROD_CAT_ID
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), ?)`,
      [
        PROD_SUB_CAT_ID, PROD_NAME, PROD_CODE, PROD_DESC, PROD_MRP, PROD_SP,
        PROD_REORDER_LEVEL, PROD_QOH, PROD_HSN_CODE, PROD_CGST, PROD_IGST,
        PROD_SGST, PROD_MFG_DATE, PROD_EXPIRY_DATE, PROD_MFG_BY, PROD_IMAGE_1,
        PROD_IMAGE_2, PROD_IMAGE_3, 'SYSTEM', 'SYSTEM', PROD_CAT_ID
      ]
    );

    res.status(201).json({ message: 'Product added successfully', productId: result.insertId });
  } catch (error) {
    console.error('Product add error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

const editProduct = async (req, res) => {
  try {
    const {
      PROD_SUB_CAT_ID,
      PROD_NAME,
      PROD_CODE,
      PROD_DESC,
      PROD_MRP,
      PROD_SP,
      PROD_REORDER_LEVEL,
      PROD_QOH,
      PROD_HSN_CODE,
      PROD_CGST,
      PROD_IGST,
      PROD_SGST,
      PROD_MFG_DATE,
      PROD_EXPIRY_DATE,
      PROD_MFG_BY,
      PROD_IMAGE_1,
      PROD_IMAGE_2,
      PROD_IMAGE_3,
      PROD_CAT_ID
    } = req.body;

    await db.query(
      `UPDATE product SET
        PROD_SUB_CAT_ID = ?, PROD_NAME = ?, PROD_CODE = ?, PROD_DESC = ?,
        PROD_MRP = ?, PROD_SP = ?, PROD_REORDER_LEVEL = ?, PROD_QOH = ?,
        PROD_HSN_CODE = ?, PROD_CGST = ?, PROD_IGST = ?, PROD_SGST = ?,
        PROD_MFG_DATE = ?, PROD_EXPIRY_DATE = ?, PROD_MFG_BY = ?, PROD_IMAGE_1 = ?,
        PROD_IMAGE_2 = ?, PROD_IMAGE_3 = ?, UPDATED_BY = ?, UPDATED_DATE = NOW(),
        PROD_CAT_ID = ?
      WHERE PROD_ID = ?`,
      [
        PROD_SUB_CAT_ID, PROD_NAME, PROD_CODE, PROD_DESC, PROD_MRP, PROD_SP,
        PROD_REORDER_LEVEL, PROD_QOH, PROD_HSN_CODE, PROD_CGST, PROD_IGST,
        PROD_SGST, PROD_MFG_DATE, PROD_EXPIRY_DATE, PROD_MFG_BY, PROD_IMAGE_1,
        PROD_IMAGE_2, PROD_IMAGE_3, 'SYSTEM', PROD_CAT_ID, req.params.id
      ]
    );

    res.json({ message: 'Product updated successfully' });
  } catch (error) {
    console.error('Product edit error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

module.exports = {
  getProductList,
  getProductDetail,
  addProduct,
  editProduct
}; 