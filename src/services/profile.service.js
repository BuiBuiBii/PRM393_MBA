const { apiMessages } = require('../utils/constants');

const buildReadyPayload = () => ({
  message: apiMessages.ready,
  data: null,
});

const getMyProfile = async () => buildReadyPayload();
const updateMyProfile = async () => buildReadyPayload();

module.exports = {
  getMyProfile,
  updateMyProfile,
};
