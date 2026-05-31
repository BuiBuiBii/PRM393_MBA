const express = require('express');

const chatController = require('../controllers/chat.controller');
const authMiddleware = require('../middlewares/auth.middleware');

const router = express.Router();

router.post('/sessions', authMiddleware, chatController.createSession);
router.post('/messages', authMiddleware, chatController.sendMessage);

module.exports = router;
