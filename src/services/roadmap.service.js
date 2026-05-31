const { apiMessages } = require('../utils/constants');

const buildReadyPayload = () => ({
  message: apiMessages.ready,
  data: null,
});

const getMyRoadmaps = async () => buildReadyPayload();

module.exports = {
  getMyRoadmaps,
};
