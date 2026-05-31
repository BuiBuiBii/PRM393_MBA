const { apiMessages } = require('../utils/constants');

const buildReadyPayload = () => ({
  message: apiMessages.ready,
  data: null,
});

const analyzeWithAi = async () => buildReadyPayload();

module.exports = {
  analyzeWithAi,
};
