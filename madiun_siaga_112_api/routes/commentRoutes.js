// routes/commentRoutes.js
const express = require('express');
const router = express.Router();
const commentController = require('../controllers/commentController');
const authMiddleware = require('../middleware/authMiddleware');

router.get('/', commentController.getComments);
router.post('/', authMiddleware, commentController.addComment);

module.exports = router;