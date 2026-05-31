const express = require('express');

const profileController = require('../controllers/profile.controller');
const authMiddleware = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const { validateProfileBody } = require('../validators/profile.validator');

const router = express.Router();

router.get('/me', authMiddleware, profileController.getMe);
router.patch('/me', authMiddleware, validate(validateProfileBody), profileController.updateMe);

module.exports = router;
