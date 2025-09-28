// routes/ambulanceRoutes.js
const express = require('express');
const router = express.Router();
const ambulanceController = require('../controllers/ambulanceController');
const authMiddleware = require('../middleware/authMiddleware');

router.get('/locations', ambulanceController.getLocations);
router.post('/update-location', authMiddleware, ambulanceController.updateLocation);

module.exports = router;