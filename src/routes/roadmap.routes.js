const express = require('express');

const roadmapController = require('../controllers/roadmap.controller');
const authMiddleware = require('../middlewares/auth.middleware');

const router = express.Router();

router.get('/me', authMiddleware, roadmapController.getMyRoadmaps);

module.exports = router;
