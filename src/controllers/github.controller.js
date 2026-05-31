const githubService = require('../services/github.service');
const { successResponse } = require('../utils/response');

const getRepositories = async (req, res, next) => {
  try {
    const result = await githubService.listRepositories(req.user);
    return successResponse(res, result.message, result.data);
  } catch (error) {
    return next(error);
  }
};

const connectGithub = async (req, res, next) => {
  try {
    const result = await githubService.connectGithub({ user: req.user, body: req.body });
    return successResponse(res, result.message, result.data);
  } catch (error) {
    return next(error);
  }
};

module.exports = {
  getRepositories,
  connectGithub,
};
