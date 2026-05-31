const profileService = require('../services/profile.service');
const { successResponse } = require('../utils/response');

const getMe = async (req, res, next) => {
  try {
    const result = await profileService.getMyProfile(req.user);
    return successResponse(res, result.message, result.data);
  } catch (error) {
    return next(error);
  }
};

const updateMe = async (req, res, next) => {
  try {
    const result = await profileService.updateMyProfile({ user: req.user, body: req.body });
    return successResponse(res, result.message, result.data);
  } catch (error) {
    return next(error);
  }
};

module.exports = {
  getMe,
  updateMe,
};
