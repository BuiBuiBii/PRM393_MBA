const authService = require('../services/auth.service');
const { successResponse } = require('../utils/response');

const register = async (req, res, next) => {
  try {
    const result = await authService.registerUser(req.body);
    return successResponse(res, result.message, result.data);
  } catch (error) {
    return next(error);
  }
};

const login = async (req, res, next) => {
  try {
    const result = await authService.loginUser(req.body);
    return successResponse(res, result.message, result.data);
  } catch (error) {
    return next(error);
  }
};

const getMe = async (req, res, next) => {
  try {
    const result = await authService.getCurrentUser(req.user);
    return successResponse(res, result.message, result.data);
  } catch (error) {
    return next(error);
  }
};

module.exports = {
  register,
  login,
  getMe,
};
