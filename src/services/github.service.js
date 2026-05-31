const { apiMessages } = require('../utils/constants');

const buildReadyPayload = () => ({
  message: apiMessages.ready,
  data: null,
});

const listRepositories = async () => buildReadyPayload();
const connectGithub = async () => buildReadyPayload();

module.exports = {
  listRepositories,
  connectGithub,
};
