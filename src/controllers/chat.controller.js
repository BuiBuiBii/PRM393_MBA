const chatService = require('../services/chat.service');
const { successResponse } = require('../utils/response');

const createSession = async (req, res, next) => {
  try {
    const result = await chatService.createSession({ user: req.user, body: req.body });
    return successResponse(res, result.message, result.data);
  } catch (error) {
    return next(error);
  }
};

const sendMessage = async (req, res, next) => {
  try {
    const result = await chatService.sendMessage({ user: req.user, body: req.body });
    return successResponse(res, result.message, result.data);
  } catch (error) {
    return next(error);
  }
};

module.exports = {
  createSession,
  sendMessage,
};
