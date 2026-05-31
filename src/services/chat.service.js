const { apiMessages } = require('../utils/constants');

const buildReadyPayload = () => ({
  message: apiMessages.ready,
  data: null,
});

const createSession = async () => buildReadyPayload();
const sendMessage = async () => buildReadyPayload();

module.exports = {
  createSession,
  sendMessage,
};
