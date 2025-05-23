const express = require('express');
const router = express.Router();
const { getRetailerList, getRetailerDetails } = require('../controllers/retailerController');
const auth = require('../middleware/auth');

router.get('/retailerlist', getRetailerList);
router.get('/retailerdetails/:id', getRetailerDetails);

module.exports = router; 