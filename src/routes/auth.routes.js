const express = require('express');

const authController = require('../controllers/auth.controller');
const authMiddleware = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const {
  validateRegisterBody,
  validateLoginBody,
} = require('../validators/auth.validator');

const router = express.Router();

router.post('/register', validate(validateRegisterBody), authController.register);
router.post('/login', validate(validateLoginBody), authController.login);
router.get('/me', authMiddleware, authController.getMe);

module.exports = router;
