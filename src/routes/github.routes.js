const express = require('express');

const githubController = require('../controllers/github.controller');
const authMiddleware = require('../middlewares/auth.middleware');

const router = express.Router();

router.get('/repositories', authMiddleware, githubController.getRepositories);
router.post('/connect', authMiddleware, githubController.connectGithub);

module.exports = router;
