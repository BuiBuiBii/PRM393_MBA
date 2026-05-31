const { apiMessages } = require('../utils/constants');

const buildReadyPayload = () => ({
  message: apiMessages.ready,
  data: null,
});

const analyzeRepository = async () => buildReadyPayload();
const getAnalysisResults = async () => buildReadyPayload();

module.exports = {
  analyzeRepository,
  getAnalysisResults,
};
