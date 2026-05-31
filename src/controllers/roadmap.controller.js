const roadmapService = require('../services/roadmap.service');
const { successResponse } = require('../utils/response');

const getMyRoadmaps = async (req, res, next) => {
  try {
    const result = await roadmapService.getMyRoadmaps(req.user);
    return successResponse(res, result.message, result.data);
  } catch (error) {
    return next(error);
  }
};

module.exports = {
  getMyRoadmaps,
};
