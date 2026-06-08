const mongoose = require('mongoose');

const Report = require('../models/Report');

const createStatusError = (message, statusCode) => {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
};

const createReport = async ({ authUser, body }) => {
  const reporterId = authUser && (authUser.userId || authUser.id);

  if (!reporterId) {
    throw createStatusError('Unauthorized', 401);
  }

  const targetType = String(body.targetType || 'other').trim();
  const targetId = body.targetId ? String(body.targetId).trim() : null;
  const reason = String(body.reason || '').trim();
  const description = String(body.description || '').trim();

  if (!['user', 'repository', 'analysis', 'ai_feedback', 'roadmap', 'other'].includes(targetType)) {
    throw createStatusError('targetType is invalid', 400);
  }

  if (targetId && !mongoose.Types.ObjectId.isValid(targetId)) {
    throw createStatusError('targetId is invalid', 400);
  }

  if (!reason) {
    throw createStatusError('reason is required', 400);
  }

  const report = await Report.create({
    reporterId,
    targetType,
    targetId: targetId || null,
    reason,
    description,
  });

  return {
    message: 'Report created successfully',
    data: { report: report.toObject() },
    statusCode: 201,
  };
};

module.exports = {
  createReport,
};
