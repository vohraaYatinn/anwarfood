const { pool: db } = require('../config/database');

const getCategoryList = async (req, res) => {
  try {
    const [categories] = await db.promise().query(`
      SELECT c.*, 
      GROUP_CONCAT(sc.SUB_CATEGORY_ID, ':', sc.SUB_CATEGORY_NAME) as sub_categories
      FROM category c
      LEFT JOIN sub_category sc ON c.CATEGORY_ID = sc.SUB_CATEGORY_CAT_ID
      WHERE c.DEL_STATUS != 'Y'
      GROUP BY c.CATEGORY_ID
    `);

    // Format sub-categories
    const formattedCategories = categories.map(category => ({
      ...category,
      sub_categories: category.sub_categories
        ? category.sub_categories.split(',').map(sub => {
            const [id, name] = sub.split(':');
            return { id, name };
          })
        : []
    }));

    res.json({
      success: true,
      data: formattedCategories
    });
  } catch (error) {
    console.error('Error fetching categories:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching categories',
      error: error.message
    });
  }
};

module.exports = {
  getCategoryList
}; 