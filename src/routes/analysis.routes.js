const express = require('express');

const analysisController = require('../controllers/analysis.controller');
const authMiddleware = require('../middlewares/auth.middleware');

const router = express.Router();

router.post('/repositories/:repoId', authMiddleware, analysisController.analyzeRepository);
router.get('/results/:repoId', authMiddleware, analysisController.getAnalysisResults);

module.exports = router;
