const { apiMessages } = require('../utils/constants');

const buildReadyPayload = () => ({
  message: apiMessages.ready,
  data: null,
});

const registerUser = async () => buildReadyPayload();
const loginUser = async () => buildReadyPayload();
const getCurrentUser = async () => buildReadyPayload();

module.exports = {
  registerUser,
  loginUser,
  getCurrentUser,
};
